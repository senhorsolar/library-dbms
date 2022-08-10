DROP TRIGGER IF EXISTS AddToInventory;
DROP TRIGGER IF EXISTS RemoveFromInventory;
DROP TRIGGER IF EXISTS SetMemberExpiry;
DROP TRIGGER IF EXISTS BeforeRemoveMember;
DROP TRIGGER IF EXISTS BeforeCheckout;
DROP TRIGGER IF EXISTS AfterCheckout;
DROP TRIGGER IF EXISTS BeforeDeleteCheckout;
DROP TRIGGER IF EXISTS AfterDeleteCheckout;
DROP TRIGGER IF EXISTS BeforeReservation;
DROP TRIGGER IF EXISTS AfterReservation;
DROP TRIGGER IF EXISTS DeleteReservation;
DROP TRIGGER IF EXISTS UpdateLateFee;
DROP EVENT IF EXISTS PeriodicEvent; -- Time event

-- Book/Inventory: When inserting into Book, add to inventory
CREATE TRIGGER AddToInventory BEFORE INSERT
ON Book FOR EACH ROW
BEGIN
    IF NEW.inventoryId is NULL THEN
        INSERT INTO Inventory(status) VALUES ('in-stock');
        SET NEW.inventoryId = (SELECT LAST_INSERT_ID());
    END IF;
END;

-- Book/Inventory: When removing Book, remove from inventory
CREATE TRIGGER RemoveFromInventory BEFORE DELETE
ON Book FOR EACH ROW
BEGIN
    DELETE FROM Inventory WHERE Inventory.id=OLD.inventoryId;
END;

-- Member: Set expiry date for member on insert
CREATE TRIGGER SetMemberExpiry BEFORE INSERT
ON Member FOR EACH ROW
BEGIN
    IF NEW.issueDate IS NULL THEN
        SET NEW.issueDate = (SELECT CURRENT_DATE);
        SET NEW.expiryDate = (SELECT DATE_ADD(CURRENT_DATE, INTERVAL 1 YEAR));
    END IF;
END;

-- Member/Checkout: Refuse removal of member if still has checkout
CREATE TRIGGER BeforeRemoveMember BEFORE DELETE
ON Member FOR EACH ROW
BEGIN
    IF EXISTS (SELECT memberId FROM Checkout WHERE memberId=OLD.id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Cannot delete member which has existing checkouts";
    END IF;
END;

-- Member/Checkout/LateFee: cannot checkout if currently has late fee
-- Checkout/Inventory: Can only checkout if in-stock or same member has reserved (remove from reservation)
CREATE TRIGGER BeforeCheckout BEFORE INSERT
ON Checkout FOR EACH ROW
BEGIN
    -- Check if current membership not expired
    IF EXISTS (SELECT Member.id FROM Member
               WHERE Member.id=NEW.memberId AND Member.expiryDate < CURRENT_DATE
              ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Member with expired membership cannot checkout an item";
    END IF;
    -- Check for late fee
    IF EXISTS (SELECT LateFee.id FROM LateFee, Checkout 
               WHERE Checkout.memberId=NEW.memberId AND Checkout.id=LateFee.checkoutId
              ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Member with late fees cannot checkout another item";
    END IF;
    -- Ensure in-stock
    IF NOT EXISTS (SELECT Inventory.id FROM Inventory
                   WHERE Inventory.status = 'in-stock' AND Inventory.id=NEW.inventoryId
                  ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Cannot checkout reserved or out of stock item";
    END IF;
    -- Update checkout and due dates
    IF NEW.checkoutDate IS NULL THEN
        SET NEW.checkoutDate = (SELECT CURRENT_DATE);
        SET NEW.dueDate = (SELECT DATE_ADD(CURRENT_DATE, INTERVAL 30 DAY));
    END IF;
END;

-- Checkout/Inventory: Update inventory to checked-out
CREATE TRIGGER AfterCheckout AFTER INSERT
ON Checkout FOR EACH ROW
BEGIN
    UPDATE Inventory
    SET status = 'checked-out'
    WHERE NEW.inventoryId = Inventory.id;
END;

-- Checkout/Inventory: Delete checkout updates inventory to in-stock
CREATE TRIGGER BeforeDeleteCheckout BEFORE DELETE
ON Checkout FOR EACH ROW
BEGIN
    UPDATE Inventory
    SET status = 'in-stock'
    WHERE OLD.inventoryId = Inventory.id;
END;

-- Checkout/Log: Delete checkout adds to log
CREATE TRIGGER AfterDeleteCheckout AFTER DELETE
ON Checkout FOR EACH ROW
BEGIN
    INSERT INTO Log(memberId, inventoryId, checkoutDate, dueDate, returnDate)
    VALUES(OLD.memberId, OLD.inventoryId, OLD.checkoutDate, OLD.dueDate, CURRENT_DATE);
END;

-- Reservation: Set dateReserved
CREATE TRIGGER BeforeReservation BEFORE INSERT
ON Reservation FOR EACH ROW
BEGIN
    -- Check if current membership not expired
    IF EXISTS (SELECT Member.id FROM Member
               WHERE Member.id=NEW.memberId AND Member.expiryDate < CURRENT_DATE
              ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Member with expired membership cannot reserve an item";
    END IF;
    -- Check for late fee
    IF EXISTS (SELECT LateFee.id FROM LateFee, Checkout 
               WHERE Checkout.memberId=NEW.memberId AND Checkout.id=LateFee.checkoutId
              ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Member with late fees cannot reserve an item";
    END IF;
    -- Ensure in-stock
    IF NOT EXISTS (SELECT Inventory.id FROM Inventory
                   WHERE Inventory.status = 'in-stock' AND Inventory.id=NEW.inventoryId
                  ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = "Cannot reserve an already reserved or out of stock item";
    END IF;
    IF NEW.reservedUntil IS NULL THEN
        SET NEW.reservedUntil = DATE_ADD(CURRENT_DATE, INTERVAL 5 DAY);
    END IF;
END;

-- Reservation/Inventory: Update inventory to reserved
CREATE TRIGGER AfterReservation AFTER INSERT
ON Reservation FOR EACH ROW
BEGIN
    UPDATE Inventory
    SET status = 'reserved'
    WHERE NEW.inventoryId = Inventory.id;
END;

-- Reservation/Inventory: Update inventory to in-stock
CREATE TRIGGER DeleteReservation AFTER DELETE
ON Reservation FOR EACH ROW
BEGIN
    UPDATE Inventory
    SET status = 'in-stock'
    WHERE OLD.inventoryId = Inventory.id;
END;

-- LateFee:
-- Prevent amount from going past max of $20
CREATE TRIGGER UpdateLateFee BEFORE UPDATE
ON LateFee FOR EACH ROW
BEGIN
    IF NEW.amount > 20 THEN
        SET NEW.amount = 20;
    END IF;
END;

-- LateFee: Update amount due every day past due
CREATE EVENT PeriodicEvent
ON SCHEDULE
    EVERY 1 SECOND
    DO
        BEGIN
            -- Update late fees
            UPDATE LateFee
                SET amount = amount + 1;
                
            -- Check if any Checkouts just became late
            INSERT INTO LateFee(amount, checkoutId)
                SELECT 0, Checkout.id as checkoutId
                FROM Checkout
                WHERE Checkout.id NOT IN (
                    SELECT LateFee.checkoutId FROM LateFee
                )
                AND Checkout.dueDate < CURRENT_DATE;
                
            -- Check if reservations too long
            DELETE FROM Reservation
               WHERE CURRENT_DATE >= reservedUntil;
        END;