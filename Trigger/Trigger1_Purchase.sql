ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'DD/MM/YYYY HH24:MI:SS';

DROP trigger trg_newPurchase;

-- Action should do 

-- Insert 
-- 1. Check amount ( if not enough then return error message )
-- 2. Get the SellingPrice ( Item Table )
-- 3. TotalPrice ( Purchase ) ItemPrice ( Item ) * Quantity ( Purchase )
-- 4. QuantityInStock ( Item ) = QuantityInStock ( Item ) - Quantity ( Purchase ) 

-- Update 
-- 1. get Quantity ( Purchase ) 
-- 2. compare :NEW and :OLD Quantity
-- 3. if more than, then need to check QuantityInStock ( Item ) 
-- 4. if smaller than, then need to count the different between and add at the QuantityInStock ( Item )
-- 5. calculate a :NEW TotalPrice

-- Delete 
-- 1. Get the item QuantityInStock ( Item )
-- 2. Get Quantity ( Purchase )
-- 3. QuantityInStock ( Item ) = QuantityInStock ( Item ) + Quantity ( Purchase )
-- 4. Update QuantityInStock ( Item ) 


CREATE OR REPLACE TRIGGER trg_newPurchase
BEFORE INSERT OR UPDATE OR DELETE ON Purchase
FOR EACH ROW 

DECLARE
price Item.SellingPrice%TYPE;
oldItemQtyInStock Item.QuantityInStock%TYPE;
newItemQtyInStock Item.QuantityInStock%TYPE;

BEGIN 

CASE 
    WHEN INSERTING THEN 
        -- SELECT item 
        SELECT SellingPrice, QuantityInStock INTO price, newItemQtyInStock
        FROM Item 
        WHERE ItemID = :NEW.ItemID; 

        IF (:NEW.Quantity <= newItemQtyInStock) THEN
            -- still have stock
            -- get price  
            -- calculate total`
            :NEW.ItemBuyPrice := price;
            :NEW.TotalPrice := price * :NEW.Quantity;
            newItemQtyInStock := newItemQtyInStock - :NEW.Quantity;

            -- update new QuantityInStock
            UPDATE Item 
            SET QuantityInStock = newItemQtyInStock
            WHERE Item.ItemID = :NEW.ItemID;
        ELSE 
            RAISE_APPLICATION_ERROR(-20000, 'The amount of Item request is more than quantity in stock. Item ' || :NEW.ItemID ||  ' Current quantity in stock is : ' || newItemQtyInStock || '. The amount you request is : ' || :NEW.Quantity);
        END IF;
    WHEN UPDATING THEN 
        -- check is same item or not 
        IF (:NEW.ItemID = :OLD.ItemID) THEN 
            -- GET ITEM QuantityInStock
            SELECT QuantityInStock INTO oldItemQtyInStock
            FROM Item 
            WHERE ItemID = :OLD.ItemID; 

            -- return back the old quantity 
            oldItemQtyInStock := oldItemQtyInStock + :OLD.Quantity;

            -- check qty allow ?
            IF (:NEW.Quantity <= oldItemQtyInStock) THEN
                -- if allow
                -- recalculate price 
                :NEW.TotalPrice := :OLD.ItemBuyPrice * :NEW.Quantity;

                -- update QuantityInStock ( Item )
                oldItemQtyInStock := oldItemQtyInStock - :NEW.Quantity;

                UPDATE Item 
                SET QuantityInStock = oldItemQtyInStock
                WHERE Item.ItemID = :NEW.ItemID;
            ELSE
                -- OVER LIMIT
                RAISE_APPLICATION_ERROR(-20000, 'The amount request to update is exceed the amount that exist in stock. Amount request to adding : ' || :NEW.Quantity - :OLD.Quantity || ' The amount currently exist is : ' || oldItemQtyInStock - :OLD.Quantity);
            END IF;
        ELSE 
            -- NOT SAME 
            -- GET NEW ITEM 
            SELECT SellingPrice, QuantityInStock INTO price, newItemQtyInStock
            FROM Item
            WHERE ItemID = :NEW.ItemID;

            IF (:NEW.Quantity <= newItemQtyInStock) THEN
                -- available 
                :NEW.ItemBuyPrice := price;
                :NEW.TotalPrice := price * :NEW.Quantity;
                
                -- return value to old 
                SELECT QuantityInStock INTO oldItemQtyInStock
                FROM Item 
                WHERE ItemID = :OLD.ItemID;

                oldItemQtyInStock := oldItemQtyInStock + :OLD.Quantity;

                UPDATE Item
                SET QuantityInStock = oldItemQtyInStock
                WHERE ItemID = :OLD.ItemID;

                -- update new item 
                newItemQtyInStock := newItemQtyInStock - :NEW.Quantity;

                UPDATE Item
                SET QuantityInStock = newItemQtyInStock
                WHERE ItemID = :NEW.ItemID;
            ELSE 
                -- NEW OVERLIMIT 
                RAISE_APPLICATION_ERROR(-20000, 'The amount of Item request is more than quantity in stock. Item ' || :NEW.ItemID ||  ' Current quantity in stock is : ' || newItemQtyInStock || '. The amount you request is : ' || :NEW.Quantity);
            END IF;
        END IF;
    WHEN DELETING THEN
        SELECT QuantityInStock INTO oldItemQtyInStock
        FROM Item 
        WHERE ItemID = :OLD.ItemID;

        oldItemQtyInStock := oldItemQtyInStock + :OLD.Quantity;

        UPDATE Item
        SET QuantityInStock = oldItemQtyInStock
        WHERE ItemID = :OLD.ItemID;
END CASE;
END;
/


-- TESTING 

-- Insert test 
INSERT INTO Purchase (PassengerID, ItemID, Quantity, ItemBuyPrice, TotalPrice, PurchaseDate) VALUES ('P0003', 'I0020', '8', NULL, NULL, '9/7/2024');

SELECT *
FROM Purchase
WHERE PassengerID = 'P0003' AND
        ItemID = 'I0020' AND
        PurchaseDate = '09/07/2024';

-- update test ( same item, decrease number of quantity )
SELECT *
FROM Item 
WHERE ItemID = 'I0016';

SELECT *
FROM Purchase
WHERE PassengerID = 'P0003' AND
        ItemID = 'I0016' AND
        PurchaseDate = '04/07/2024';

UPDATE Purchase
SET Quantity = 5
WHERE PassengerID = 'P0003' AND 
        ItemID = 'I0016' AND
        PurchaseDate = '04/07/2024';

SELECT *
FROM Purchase
WHERE PassengerID = 'P0003' AND
        ItemID = 'I0016' AND
        PurchaseDate = '04/07/2024';

-- update test ( same item, increase number of quantity )
UPDATE Purchase
SET Quantity = 50
WHERE PassengerID = 'P0003' AND 
        ItemID = 'I0016' AND
        PurchaseDate = '04/07/2024';

-- update test ( different item I0016 to I0010, increase number of quantity )
SELECT *
FROM Purchase
WHERE PassengerID = 'P0003' AND
        ItemID = 'I0016' AND
        PurchaseDate = '04/07/2024';

UPDATE Purchase
SET Quantity = 60,
    ItemID = 'I0010'
WHERE PassengerID = 'P0003' AND 
        ItemID = 'I0016' AND
        PurchaseDate = '04/07/2024';

SELECT *
FROM Purchase
WHERE PassengerID = 'P0003' AND
        ItemID = 'I0010' AND
        PurchaseDate = '04/07/2024';

-- delete purchase 
SELECT *
FROM Item 
WHERE ItemID = 'I0010';

DELETE FROM PURCHASE 
WHERE PassengerID = 'P0003' AND
        ItemID = 'I0010' AND
        PurchaseDate = '04/07/2024';

SELECT *
FROM Item 
WHERE ItemID = 'I0010';








-- INSERT , RUN INSERT FILE 
-- RUN THIS TO KNOW THE RESULT 
SELECT * FROM PURCHASE;

-- UPDATE RECORD TEST USE THIS 
SELECT * 
FROM PURCHASE
WHERE PassengerID = 'P0003' AND 
        ItemID = 'I0016' AND
        PurchaseDate = '04/07/2024';

-- FOR VIEW THOSE ITEM DETAILS
SELECT * 
FROM Item
WHERE ItemID = 'I0016';

SELECT * 
FROM Item
WHERE ItemID = 'I0010';



SELECT * 
FROM PURCHASE
WHERE PassengerID = 'P0003' AND 
        ItemID = 'I0010' AND
        PurchaseDate = '04/07/2024';



SELECT * 
FROM Item
WHERE ItemID = 'I0010';
