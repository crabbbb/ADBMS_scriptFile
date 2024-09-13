-- PLS SET THIS TO GET DISPLAY THE MESSAGE 
SET SERVEROUTPUT ON

ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'DD/MM/YYYY HH24:MI:SS';

set linesize 250
set pagesize 100

-- preference of those passenger in flightschedule XXX

-- 1. passenger who are in this flightschedule
--     - passenger details
--     - 
-- 2. each passenger choose the top one based on their purchase record 
-- 3. calculate the how much out of how much, eg 1/6
DROP PROCEDURE passengerPreference;

CREATE OR REPLACE PROCEDURE passengerPreference (fID IN VARCHAR2) IS

pID         Passenger.PassengerID%TYPE;
control     NUMBER(1);
ttlRecord   NUMBER(2);

CURSOR passengerCursor IS 
    SELECT p.* 
    FROM BookingDetail b, FlightSchedule f, Passenger p
    WHERE b.PassengerID = p.PassengerID AND
            b.FlightScheduleID = f.FlightScheduleID AND
            f.FlightScheduleID = fID;

-- most rencently buy 
CURSOR rencentCursor IS 
    SELECT i.Category, COUNT(i.ItemID) AS NoOfPurchase, SUM(p.Quantity) AS TtlQtyBuy, SUM(p.Quantity * p.ItemBuyPrice) AS TtlPricePaid
    FROM Purchase p, Item i
    WHERE p.ItemID = i.ItemID AND
            p.PassengerID = pID 
    GROUP BY i.Category
    ORDER BY NoOfPurchase DESC;

passengerRec passengerCursor%ROWTYPE;
rencentRec rencentCursor%ROWTYPE;

BEGIN
    -- TITLE
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 170, '='));
    DBMS_OUTPUT.PUT_LINE(CHR(10));
    DBMS_OUTPUT.PUT_LINE('PASSENGER PREFERENCE FOR FLIGHT SCHEDULE - ' || fID);
    DBMS_OUTPUT.PUT_LINE(CHR(10));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 170, '='));

    DBMS_OUTPUT.PUT_LINE(RPAD('Passenger ID', 10, ' ') || ' ' ||
                RPAD('Passenger Name', 55, ' ') || ' ' ||
                RPAD('Passenger Gender', 20, ' ') || ' ' ||
                RPAD('Preference Category', 20, ' ')  || ' ' ||
                RPAD('No of Purchase', 15, ' ')  || ' ' ||
                RPAD('Total Quantity Buy', 20, ' ')  || ' ' ||
                RPAD('Total Price Paid', 20, ' '));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 170, '='));

    ttlRecord := 0;

    OPEN passengerCursor;
    LOOP
    FETCH passengerCursor INTO passengerRec;
    IF (passengerCursor%ROWCOUNT = 0) THEN 
        DBMS_OUTPUT.PUT_LINE('This Flight Schedule doesnot have any passenger yet');
    END IF;
    EXIT WHEN passengerCursor%NOTFOUND;

        pID := passengerRec.PassengerID;
        control := 0;

        OPEN rencentCursor;
        LOOP
        FETCH rencentCursor INTO rencentRec;
        IF (rencentCursor%ROWCOUNT = 0) THEN 
            DBMS_OUTPUT.PUT_LINE(RPAD(passengerRec.PassengerID, 10, ' ') || ' ' ||
                        RPAD(passengerRec.PassengerName, 55, ' ') || ' ' ||
                        RPAD(getGender(passengerRec.PassengerGender), 20, ' ') || ' ' ||
                        RPAD('This passenger doesnot buy any item before', 75, ' '));
        END IF;
        EXIT WHEN rencentCursor%NOTFOUND;

        IF (control = 0) THEN
            DBMS_OUTPUT.PUT_LINE(RPAD(passengerRec.PassengerID, 10, ' ') || ' ' ||
                        RPAD(passengerRec.PassengerName, 55, ' ') || ' ' ||
                        RPAD(getGender(passengerRec.PassengerGender), 20, ' ') || ' ' ||
                        RPAD(rencentRec.Category, 20, ' ')  || ' ' ||
                        RPAD(rencentRec.NoOfPurchase, 15, ' ')  || ' ' ||
                        RPAD(rencentRec.TtlQtyBuy, 20, ' ')  || ' ' ||
                        RPAD(getPriceFormat(rencentRec.TtlPricePaid), 20, ' '));
            control := control + 1;
        END IF;

        END LOOP;
        CLOSE rencentCursor;

        ttlRecord := ttlRecord + 1;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(RPAD('=', 170, '='));
    DBMS_OUTPUT.PUT_LINE(CHR(10));
    DBMS_OUTPUT.PUT_LINE('TOTAL NO OF PASSENGER IN THIS FLIGHT SCHEDULE - ' || fID || ' IS ' || ttlRecord);
    DBMS_OUTPUT.PUT_LINE(CHR(10));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 170, '='));

    CLOSE passengerCursor;

END;
/

-- CHECKING 
SELECT * 
FROM BookingDetail b, FlightSchedule f, Passenger p
WHERE b.PassengerID = p.PassengerID AND
        b.FlightScheduleID = f.FlightScheduleID AND
        f.FlightScheduleID = 'FS0237';

select f.flightscheduleID, count(p.passengerID) 
from flightschedule f, bookingdetail b, passenger p 
where b.passengerid = p.passengerid and b.flightscheduleid = f.flightscheduleid 
group by f.flightscheduleid 
order by count(p.passengerid) desc;

/*
Result :

FLIGHT COUNT(P.PASSENGERID)
------ --------------------
FS0237                    5
FS0087                    5
FS0241                    5
FS0121                    5
FS0204                    5
FS0098                    5
FS0095                    5
FS0116                    5
FS0032                    5
FS0216                    5
*/

SELECT i.Category, COUNT(i.ItemID) AS NoOfPurchase, SUM(p.Quantity) AS TtlQtyBuy, SUM(p.Quantity * p.ItemBuyPrice) AS TtlPricePaid
    FROM Purchase p, Item i
    WHERE p.ItemID = i.ItemID AND
            p.PassengerID = 'P0001' 
    GROUP BY i.Category
    ORDER BY NoOfPurchase DESC;

EXEC passengerPreference('FS0237');

-- try if no purchase record 
DELETE FROM Purchase
WHERE PassengerID = 'P0001';