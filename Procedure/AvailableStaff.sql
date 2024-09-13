-- PLS SET THIS TO GET DISPLAY THE MESSAGE 
SET SERVEROUTPUT ON

ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'DD/MM/YYYY HH24:MI:SS';

set linesize 250
set pagesize 100
-- who are the available staff on the day ✅ ( exclude leave ✅, exclude the person who have exceed the maximum fly time ✅ ), if success then add into database
-- input workingHours, find out who have exceed the maximum fly time
-- count the fly time left ✅

DROP PROCEDURE availableStaff;

CREATE OR REPLACE PROCEDURE availableStaff(targetDate IN DATE, maxflyTime IN NUMBER) IS

ttlNumberOfStaff    NUMBER(2);
sID                 Staff.StaffID%TYPE;
headerOn            NUMBER(1);

-- get list of staff FLY TIME which doesnot exceed maxflyTime
CURSOR flyTimeCursor IS
    SELECT s.StaffID, COUNT(f.FlightScheduleID) AS ttlFlight, SUM(f.FlightDuration) AS ttlFlyTime
    FROM FlightSchedule f, StaffSchedule ss, Staff s
    WHERE ss.FlightScheduleID = f.FlightScheduleID AND
            ss.StaffID = s.StaffID AND
            TRUNC(f.DepartDateTime, 'MONTH') = TRUNC(to_date(targetDate, 'DD/MM/YYYY'), 'MONTH') AND
            TRUNC(f.DepartDateTime, 'YEAR') = TRUNC(to_date(targetDate, 'DD/MM/YYYY'), 'YEAR') 
    GROUP BY s.StaffID
    HAVING SUM(f.FlightDuration) < maxflyTime
    ORDER BY s.StaffID;

-- get who have take leave at the day
CURSOR staffLeaveCursor IS
    SELECT *
    FROM Leave
    WHERE StaffID = sID AND
            TRUNC(LeaveDate) = TRUNC(targetDate) AND
            UPPER(LeaveStatus) != 'REJECT';

flyTimeRec flyTimeCursor%ROWTYPE;
leaveRec staffLeaveCursor%ROWTYPE;

BEGIN
    -- TITLE
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 120, '='));
    DBMS_OUTPUT.PUT_LINE(CHR(10));
    DBMS_OUTPUT.PUT_LINE('STAFF AVAILABLE AT DATE - ' || TO_CHAR(TRUNC(targetDate), 'DD/MM/YYYY'));
    DBMS_OUTPUT.PUT_LINE(CHR(10));
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 120, '='));
    
    ttlNumberOfStaff := 0;
    headerOn := 0;

    OPEN flyTimeCursor;
    LOOP
    FETCH flyTimeCursor INTO flyTimeRec;

    IF (flyTimeCursor%ROWCOUNT = 0) THEN 
        DBMS_OUTPUT.PUT_LINE('Doesnot have available staff, all the staff have more than equals ' || maxflyTime || ' hours fly time');
    END IF;
    EXIT WHEN flyTimeCursor%NOTFOUND;

    -- GET STAFFID
    sID := flyTimeRec.StaffID;

    IF (headerOn = 0) THEN
        -- HEADING
        DBMS_OUTPUT.PUT_LINE(CHR(10));
        DBMS_OUTPUT.PUT_LINE('ALL THE RESULT GENERATE IS DEPENDS ON VALUE BELOW');
        DBMS_OUTPUT.PUT_LINE('MONTH        : ' || TO_CHAR(TRUNC(targetDate), 'DD/MM/YYYY'));
        DBMS_OUTPUT.PUT_LINE('MAX FLY TIME : ' || maxflyTime);
        DBMS_OUTPUT.PUT_LINE(CHR(10));

        DBMS_OUTPUT.PUT_LINE(RPAD('Staff ID', 10, ' ') || ' ' ||
                    RPAD('Total Schedule Attend', 40, ' ') || ' ' ||
                    RPAD('Total Fly Time', 10, ' ') || ' ' ||
                    RPAD('Fly Time Left', 15, ' '));
        
        DBMS_OUTPUT.PUT_LINE(LPAD('=', 120, '='));
        headerOn := 1;
    END IF;

        -- nested loop, GET STAFFID
        OPEN staffLeaveCursor;
        LOOP
        FETCH staffLeaveCursor INTO leaveRec; 

        -- check exist in cursor 
        IF (staffLeaveCursor%ROWCOUNT = 0) THEN 
            -- HEADING
            DBMS_OUTPUT.PUT_LINE(RPAD(sID, 10, ' ') || ' ' ||
                        RPAD(flyTimeRec.ttlFlight, 40, ' ') || ' ' ||
                        RPAD(flyTimeRec.ttlFlyTime, 10, ' ') || ' ' ||
                        RPAD((maxflyTime - flyTimeRec.ttlFlyTime), 15, ' '));
            
            ttlNumberOfStaff := ttlNumberOfStaff + 1;
        END IF;

        EXIT WHEN staffLeaveCursor%NOTFOUND;
        END LOOP;
        CLOSE staffLeaveCursor;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(CHR(10));
    DBMS_OUTPUT.PUT_LINE('Conclusion : ');
    DBMS_OUTPUT.PUT_LINE('Total Number of Staff Available : ' || ttlNumberOfStaff);

    CLOSE flyTimeCursor;

END;
/

-- checking 
BREAK ON StaffID;

-- staff S0002 have 29 hours fly time 
SELECT s.StaffID, COUNT(f.FlightScheduleID), SUM(f.FlightDuration)
FROM FlightSchedule f, StaffSchedule ss, Staff s
WHERE ss.FlightScheduleID = f.FlightScheduleID AND
        ss.StaffID = s.StaffID AND
        TRUNC(f.DepartDateTime, 'MONTH') = TRUNC(to_date('24/05/2025', 'DD/MM/YYYY'), 'MONTH') AND
        TRUNC(f.DepartDateTime, 'YEAR') = TRUNC(to_date('24/05/2025', 'DD/MM/YYYY'), 'YEAR') 
GROUP BY s.StaffID
HAVING SUM(f.FlightDuration) >= 30
ORDER BY s.StaffID;

CLEAR BREAKS

/*
RESULT : 

STAFF COUNT(F.FLIGHTSCHEDULEID) SUM(F.FLIGHTDURATION)
----- ------------------------- ---------------------
S0016                         7                    30
S0017                         9                    35
*/

-- staff S0002 Have leave
SELECT *
FROM Leave
WHERE TRUNC(LeaveDate) = TRUNC(to_date('24/05/2025', 'DD/MM/YYYY'));

-- will have 17 record because 2 exist flytime and S0002 is on leave
EXEC availableStaff('24/05/2025', 30);

-- try change S0002 leaveStatus to reject 
UPDATE Leave
SET LeaveStatus = 'Reject'
WHERE LeaveID = 'L0203';

EXEC availableStaff('24/05/2025', 30);
EXEC availableStaff('24/05/2025', 49);