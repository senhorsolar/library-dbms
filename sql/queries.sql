-- 
-- Description: Example queries on database
-- 

-- Most proflific author
SELECT author, COUNT(*)
FROM Book
GROUP BY author
ORDER BY COUNT(*) DESC
LIMIT 5;

-- Unavailable books
SELECT title, status
FROM Book, Inventory
WHERE status != 'in-stock'
ORDER BY RAND()
LIMIT 5;

-- Most prolific reader
SELECT name, COUNT(Checkout.id) as NumberCheckouts
FROM Member, Checkout, Inventory
    WHERE Member.id = Checkout.memberId
    AND Checkout.inventoryId = Inventory.id
GROUP BY name
ORDER BY COUNT(Checkout.id) DESC
LIMIT 10;

-- Most prolific member (checkouts plus reserves)
WITH NumCheckouts
AS (
    SELECT Member.id as id, COUNT(Checkout.id) as total
    FROM Member, Checkout, Inventory
    WHERE Member.id = Checkout.memberId
    AND Checkout.inventoryId = Inventory.id
    GROUP BY Member.id
),
NumReserves
AS (
    SELECT Member.id as id, COUNT(Reservation.id) as total
    FROM Member, Reservation, Inventory
    WHERE Member.id = Reservation.memberId
    AND Reservation.inventoryId = Inventory.id
    GROUP BY Member.id
)
SELECT name, Member.id, NumCheckouts.total + NumReserves.total as Prolificity
FROM Member
JOIN NumCheckouts ON Member.id=NumCheckouts.id
JOIN NumReserves ON Member.id=NumReserves.id
ORDER BY Prolificity DESC
LIMIT 10;

-- Simple regex query on titles
SELECT COUNT(*)
FROM Book
WHERE title LIKE 'A %' OR title LIKE 'The %'
LIMIT 10;