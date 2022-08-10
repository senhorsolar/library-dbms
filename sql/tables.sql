SET FOREIGN_KEY_CHECKS = 0; -- to avoid annoying foreign key problems
DROP TABLE IF EXISTS Inventory;
DROP TABLE IF EXISTS Book;
DROP TABLE IF EXISTS Member;
DROP TABLE IF EXISTS Checkout;
DROP TABLE IF EXISTS Reservation;
DROP TABLE IF EXISTS LateFee;
DROP TABLE IF EXISTS Log;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE Inventory(
    id SERIAL PRIMARY KEY,
    status ENUM('in-stock', 'reserved', 'checked-out') NOT NULL
);

CREATE TABLE Book(
    id SERIAL PRIMARY KEY,
    inventoryId BIGINT UNSIGNED,
    isbn VARCHAR(13),
    title VARCHAR(100) NOT NULL,
    author VARCHAR(100),
    year INT,
    FOREIGN KEY (inventoryId) 
        REFERENCES Inventory(id)
        ON DELETE CASCADE,
    Index (isbn),
    Index (title),
    Index (author)
);

CREATE TABLE Member(
    id SERIAL PRIMARY KEY,
    name VARCHAR(20) NOT NULL,
    address VARCHAR(50) NOT NULL,
    issueDate DATE, -- Set on trigger
    expiryDate DATE, -- Set on trigger
    Index (name)
);

CREATE TABLE Checkout(
    id SERIAL PRIMARY KEY,
    memberId BIGINT UNSIGNED NOT NULL,
    inventoryId BIGINT UNSIGNED NOT NULL,
    checkoutDate DATE, -- Set on trigger
    dueDate DATE, -- Set on trigger
    FOREIGN KEY (memberId) 
        REFERENCES Member(id)
        ON DELETE CASCADE,
    FOREIGN KEY (inventoryId) 
        REFERENCES Inventory(id)
        ON DELETE CASCADE,
    Index (memberId), 
    Index (inventoryId)
);

CREATE TABLE Reservation(
    id SERIAL PRIMARY KEY,
    memberId BIGINT UNSIGNED NOT NULL,
    inventoryId BIGINT UNSIGNED NOT NULL,
    reservedUntil DATE,
    FOREIGN KEY (memberId) 
        REFERENCES Member(id)
        ON DELETE CASCADE,
    FOREIGN KEY (inventoryId) 
        REFERENCES Inventory(id)
        ON DELETE CASCADE,
    Index (memberId), 
    Index (inventoryId)
);

CREATE TABLE Log(
    id SERIAL PRIMARY KEY,
    memberId BIGINT UNSIGNED NOT NULL,
    inventoryId BIGINT UNSIGNED NOT NULL,
    checkoutDate DATE NOT NULL,
    dueDate DATE NOT NULL,
    returnDate DATE NOT NULL,
    FOREIGN KEY (memberId) 
        REFERENCES Member(id)
        ON DELETE CASCADE,
    FOREIGN KEY (inventoryId) 
        REFERENCES Inventory(id)
        ON DELETE CASCADE,
    Index (memberId),
    Index (checkoutDate)
);

CREATE TABLE LateFee(
    id SERIAL PRIMARY KEY,
    amount DECIMAL(19,2) NOT NULL,
    checkoutId BIGINT UNSIGNED NOT NULL,
    CONSTRAINT NonNegAmount CHECK(
        amount >= 0
    ),
    FOREIGN KEY (checkoutId) 
        REFERENCES Checkout(id)
        ON DELETE CASCADE,
    Index (checkoutId)
);