-- PLS SET THIS TO GET DISPLAY THE MESSAGE 
SET SERVEROUTPUT ON
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'DD/MM/YYYY HH24:MI:SS';

set linesize 250
set pagesize 100

DROP PROCEDURE bestSaleCategory;

-- Best sales category of item in this month 
CREATE OR REPLACE PROCEDURE bestSaleCategory (targetDate IN DATE) IS

cat                 Item.Category%TYPE;
qtyOfItem           NUMBER(5);
qtyOfCat            NUMBER(5);
ttlCatPrice         NUMBER(11,2);
ttlCatQty           NUMBER(5);

-- CALCULATE PRICE FOR CATEGORY GET 
catTtlPrice         NUMBER(11,2);
catTtlSold          NUMBER(5);

-- GET WHICH ITEM IS HIGHERST PRICE AND SALES IN CATEGORY
priceInCatID        Item.ItemID%TYPE;
priceInCat          NUMBER(11,2);

qtyInCatID          Item.ItemID%TYPE;
qtyInCat            NUMBER(5);

-- GET WHICH CATEGORY IS HIGHERST PRICE AND SALES IN OVERALL
priceInOverallCat   Item.Category%TYPE;
priceInOverall      NUMBER(11,2);

qtyInOverallCat     Item.Category%TYPE;
qtyInOverall        NUMBER(5);

-- get category
CURSOR categoryCursor IS
    SELECT DISTINCT Category
    FROM Item;

-- get bestsale
CURSOR bestSaleCursor IS
    SELECT i.ItemID, i.ItemName, SUM(p.Quantity) AS ItemAmountSold, SUM(p.ItemBuyPrice * p.Quantity) AS ItemTotalPrice
    FROM Item i, Purchase p
    WHERE p.ItemID = i.ItemID AND
            TRUNC(p.PurchaseDate, 'YEAR') = TRUNC(to_date(targetDate, 'DD/MM/YYYY'), 'YEAR') AND
            UPPER(i.Category) = UPPER(cat)
    GROUP BY i.ItemID, i.ItemName
    ORDER BY ItemAmountSold DESC, i.ItemID;

bestRec bestSaleCursor%ROWTYPE;

BEGIN
    -- TITLE
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 120, '='));
    DBMS_OUTPUT.PUT_LINE(CHR(10));
    DBMS_OUTPUT.PUT_LINE('BEST SALES CATEGORY OF ITEM IN ' || TO_CHAR(TRUNC(targetDate, 'MONTH'), 'MONTH') || ' ' || TRUNC(targetDate, 'YEAR'));
    DBMS_OUTPUT.PUT_LINE(CHR(10));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 120, '='));

    qtyOfCat := 0;

    OPEN categoryCursor;
    LOOP
    FETCH categoryCursor INTO cat;
    IF (categoryCursor%ROWCOUNT = 0) THEN 
        DBMS_OUTPUT.PUT_LINE('Doesnot have item exist in record');
    END IF;
    EXIT WHEN categoryCursor%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(CHR(10));
        DBMS_OUTPUT.PUT_LINE('CATEGORY : ' || cat);
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 120, '-'));

        DBMS_OUTPUT.PUT_LINE(RPAD('Item ID', 10, ' ') || ' ' ||
                    RPAD('Item Name', 35, ' ') || ' ' ||
                    RPAD('Total Quantity Sold', 15, ' ') || ' ' ||
                    RPAD('Total Price Sold', 20, ' '));
        DBMS_OUTPUT.PUT_LINE(RPAD('-', 120, '-'));

        qtyOfItem := 0;
        ttlCatPrice := 0;
        ttlCatQty := 0;

        OPEN bestSaleCursor;
        LOOP
        FETCH bestSaleCursor INTO bestRec;
        -- IF (bestSaleCursor%ROWCOUNT = 0) THEN 
        --     DBMS_OUTPUT.PUT_LINE('Doesnot have item exist in record');
        -- END IF;
        EXIT WHEN bestSaleCursor%NOTFOUND;

            IF (qtyOfItem = 0) THEN
                qtyInCatID := bestRec.ItemID;
                qtyInCat := bestRec.ItemAmountSold;

                -- init
                priceInCatID := bestRec.ItemID;
                priceInCat := bestRec.ItemTotalPrice;
            END IF;

            -- already have data
            IF (qtyOfItem > 0 AND priceInCat < bestRec.ItemTotalPrice) THEN
                priceInCatID := bestRec.ItemID;
                priceInCat := bestRec.ItemTotalPrice;
            END IF;

            DBMS_OUTPUT.PUT_LINE(RPAD(bestRec.ItemID, 10, ' ') || ' ' ||
                        RPAD(bestRec.ItemName, 35, ' ') || ' ' ||
                        RPAD(bestRec.ItemAmountSold, 15, ' ') || ' ' ||
                        RPAD(getPriceFormat(bestRec.ItemTotalPrice), 20, ' '));
            
            qtyOfItem := qtyOfItem + 1;
            ttlCatPrice := ttlCatPrice + bestRec.ItemTotalPrice;
            ttlCatQty := ttlCatQty + bestRec.ItemAmountSold;

        END LOOP;

        DBMS_OUTPUT.PUT_LINE(RPAD('-', 120, '-'));
        DBMS_OUTPUT.PUT_LINE('THE ITEM THAT EARN THE HIGHEST PRICE IN THIS CATEGORY IS : ITEM - ' || 
                                priceInCatID || ' [' || getPriceFormat(priceInCat) || '] ');
        DBMS_OUTPUT.PUT_LINE('THE ITEM THAT HAVE MOST PEOPLE BUY IN THIS CATEGORY IS   : ITEM - ' || qtyInCatID || ' [' || TO_CHAR(qtyInCat, '99999') || '] ');

        DBMS_OUTPUT.PUT_LINE(CHR(10));

        DBMS_OUTPUT.PUT_LINE('THE TOTAL PRICE THIS CATEGORY GET IS              : ' || getPriceFormat(ttlCatPrice));
        DBMS_OUTPUT.PUT_LINE('THE TOTAL QUANTITY OF ITEM THIS CATEGORY SOLD IS  : ' || TO_CHAR(ttlCatQty, '99999'));

        DBMS_OUTPUT.PUT_LINE(RPAD('-', 120, '-'));

        -- init
        IF (qtyOfCat = 0) THEN
            priceInOverallCat := cat;
            priceInOverall := ttlCatPrice;

            qtyInOverallCat := cat;
            qtyInOverall := ttlCatQty;
        END IF;

        IF (qtyOfCat != 0 AND priceInOverall < ttlCatPrice) THEN
            priceInOverallCat := cat;
            priceInOverall := ttlCatPrice;
        END IF;

        IF (qtyOfCat != 0 AND qtyInOverall < ttlCatQty) THEN
            qtyInOverallCat := cat;
            qtyInOverall := ttlCatQty;
        END IF;

        qtyOfCat := qtyOfCat + 1;
        CLOSE bestSaleCursor;
    END LOOP;
    
    IF (ttlCatQty != 0) THEN
        DBMS_OUTPUT.PUT_LINE(CHR(10));
        DBMS_OUTPUT.PUT_LINE('CATEGORY THAT EARN THE HIGHEST PRICE IN THIS MONTH IS : CATEGORY - ' || priceInOverallCat || ' [' || getPriceFormat(priceInOverall) || '] ');
        DBMS_OUTPUT.PUT_LINE('CATEGORY THAT HAVE MOST PEOPLE BUY IN THIS MONTH IS   : CATEGORY - ' || qtyInOverallCat || ' [' || TO_CHAR(qtyInOverall, '99999') || '] ');
    END IF;

    CLOSE categoryCursor;

END;
/

-- CHECKING 
SELECT i.ItemID, SUM(p.Quantity) AS ItemAmountSold, SUM(P.ItemBuyPrice * P.Quantity) AS ItemTotalPrice
FROM Item i, Purchase p
WHERE p.ItemID = i.ItemID AND
        TRUNC(p.PurchaseDate, 'YEAR') = TRUNC(to_date('27/10/2024', 'DD/MM/YYYY'), 'YEAR') AND
        UPPER(i.Category) = UPPER('Dairy') 
GROUP BY i.ItemID
ORDER BY ItemAmountSold DESC, i.ItemID;

-- MAKE RECORD ON ONE ITEM SELLING WITH DIFFERENT PRICE IN SAME YEAR - 2024
UPDATE Item
SET SellingPrice = 30
WHERE ItemID = 'I0008';

INSERT INTO Purchase (PassengerID, ItemID, Quantity, ItemBuyPrice, TotalPrice, PurchaseDate) VALUES ('P0003', 'I0008', '8', NULL, NULL, '4/7/2024');

EXEC bestSaleCategory('27/10/2024');