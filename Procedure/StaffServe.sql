-- PLS SET THIS TO GET DISPLAY THE MESSAGE 
SET SERVEROUTPUT ON

-- this passenger serve by which staff, must exclude who are on leave
-- pls exclude those are on leave
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'DD/MM/YYYY HH24:MI:SS';

set linesize 250
set pagesize 100

DROP PROCEDURE staffServe;

CREATE OR REPLACE PROCEDURE staffServe(pID IN VARCHAR2, bID IN VARCHAR2, wID IN NUMBER) IS

bExist          NUMBER(1);
fID             FlightSchedule.FlightScheduleID%TYPE;
available       NUMBER(2);
notAvailable    NUMBER(2);

-- get the Get list of staff in duty 
-- 0 = no leave
-- 1 = leave
CURSOR staffCursor IS
    SELECT b.FlightScheduleID, f.DepartDateTime, f.ArriveDateTime, s.*,
            (SELECT (CASE WHEN COUNT(*) = 0 THEN 0 ELSE 1 END)
                FROM Leave l
                WHERE l.StaffID = s.StaffID AND
                        UPPER(l.LeaveStatus) = 'APPROVE' AND
                        TRUNC(l.LeaveDate) = TRUNC(f.DepartDateTime)) AS HaveLeave
    FROM BookingDetail b, FlightSchedule f, StaffSchedule ss, Staff s
    WHERE b.PassengerID = pID AND b.BookingID = bID AND b.WayID = wID AND
            f.FlightScheduleID = b.FlightScheduleID AND
            f.FlightScheduleID = ss.FlightScheduleID AND
            ss.StaffID = s.StaffID
    ORDER BY HaveLeave;

staffRec staffCursor%ROWTYPE;

BEGIN

    -- chk doesnot exist ( BOOKINGDETAIL )
    -- count either 0 or 1
    SELECT COUNT(*), FlightScheduleID INTO bExist, fID
    FROM BookingDetail
    WHERE PassengerID = pID AND BookingID = bID AND WayID = wID
    GROUP BY FlightScheduleID;

    IF (bExist = 0) THEN
        -- booking no exist 
        DBMS_OUTPUT.PUT_LINE('The following booking detail doesnot exist : ');
        DBMS_OUTPUT.PUT_LINE('BOOKING ID   : ' || bID);
        DBMS_OUTPUT.PUT_LINE('PASSENGER ID : ' || pID);
        DBMS_OUTPUT.PUT_LINE('WAY ID       : ' || wID);
    ELSE 
        -- TITLE
        DBMS_OUTPUT.PUT_LINE(RPAD('=', 120, '='));
        DBMS_OUTPUT.PUT_LINE(CHR(10));
        DBMS_OUTPUT.PUT_LINE('STAFF INCHARGE FLIGHTSCHEDULE - ' || fID);
        DBMS_OUTPUT.PUT_LINE(CHR(10));
        DBMS_OUTPUT.PUT_LINE(RPAD('=', 120, '='));

        available := 0;
        notAvailable := 0;

        OPEN staffCursor;
        LOOP
        FETCH staffCursor INTO staffRec;

        -- checking and exit loop 
        IF (staffCursor%ROWCOUNT = 0) THEN
            DBMS_OUTPUT.PUT_LINE('Doesnot have staff be assign to this Flight Schedule');
            DBMS_OUTPUT.PUT_LINE('Flight Schedule ID : ' || staffRec.FlightScheduleID);
        END IF;
        EXIT WHEN staffCursor%NOTFOUND;

        -- EXIST, start display 
        -- display no leave first 
        IF (staffRec.HaveLeave = 0) THEN
            IF (available = 0) THEN
                -- HEADING ( available )
                DBMS_OUTPUT.PUT_LINE(CHR(10));
                DBMS_OUTPUT.PUT_LINE('STAFF ON THE POST : ');
                DBMS_OUTPUT.PUT_LINE(RPAD('STAFF ID', 10, ' ') || ' ' ||
                            RPAD('STAFF NAME', 50, ' ') || ' ' ||
                            RPAD('STAFF IC', 12, ' ') || ' ' ||
                            RPAD('STAFF POSITION', 50, ' '));
                DBMS_OUTPUT.PUT_LINE(LPAD('=', 120, '='));
            END IF;

            DBMS_OUTPUT.PUT_LINE(RPAD(staffRec.StaffID, 10, ' ') || ' ' ||
                            RPAD(staffRec.StaffName, 50, ' ') || ' ' ||
                            RPAD(staffRec.StaffIC, 12, ' ') || ' ' ||
                            RPAD(staffRec.StaffPosition, 50, ' '));
            
            available := available + 1;
        ELSE 
            IF (notAvailable = 0) THEN
                -- HEADING ( notAvailable )
                DBMS_OUTPUT.PUT_LINE(CHR(10));
                DBMS_OUTPUT.PUT_LINE('STAFF ON LEAVE : ');
                DBMS_OUTPUT.PUT_LINE(RPAD('STAFF ID', 10, ' ') || ' ' ||
                            RPAD('STAFF NAME', 50, ' ') || ' ' ||
                            RPAD('STAFF IC', 12, ' ') || ' ' ||
                            RPAD('STAFF POSITION', 50, ' '));
                DBMS_OUTPUT.PUT_LINE(LPAD('=', 120, '='));
            END IF;

            DBMS_OUTPUT.PUT_LINE(RPAD(staffRec.StaffID, 10, ' ') || ' ' ||
                            RPAD(staffRec.StaffName, 50, ' ') || ' ' ||
                            RPAD(staffRec.StaffIC, 12, ' ') || ' ' ||
                            RPAD(staffRec.StaffPosition, 50, ' '));
            
            notAvailable := notAvailable + 1;
        END IF;

        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE(CHR(10));
        DBMS_OUTPUT.PUT_LINE('Conclusion : ');
        DBMS_OUTPUT.PUT_LINE('Total Number of Staff Assign   : ' || (available + notAvailable));
        DBMS_OUTPUT.PUT_LINE('Total Number of Staff On Post  : ' || available);
        DBMS_OUTPUT.PUT_LINE('Total Number of Staff On Leave : ' || notAvailable);

        CLOSE staffCursor;

    END IF;
END;
/

-- Checking 
-- S0002 Have leave ( refer back conflictSchedule.sql )
SELECT b.FlightScheduleID, f.DepartDateTime, f.ArriveDateTime, s.*,
            (SELECT (CASE WHEN COUNT(*) = 0 THEN 0 ELSE 1 END) 
                FROM Leave l
                WHERE l.StaffID = s.StaffID AND
                        UPPER(l.LeaveStatus) = 'APPROVE' AND
                        TRUNC(l.LeaveDate) = TRUNC(f.DepartDateTime)) AS HaveLeave,
            s.StaffName, s.StaffPosition, s.StaffIC
FROM BookingDetail b, FlightSchedule f, StaffSchedule ss, Staff s
WHERE b.PassengerID = 'P0007' AND b.BookingID = 'B0105' AND b.WayID = 2 AND
        f.FlightScheduleID = b.FlightScheduleID AND
        f.FlightScheduleID = ss.FlightScheduleID AND
        ss.StaffID = s.StaffID
ORDER BY HaveLeave;

/*
RESULT : 

FLIGHTSCHEDULEID     DEPARTDATETIME       ARRIVEDATETIME       STAFF  HaveLeave
-------------------- -------------------- -------------------- ----- ----------
FS0243               24/05/2025 20:31:00  24/05/2025 22:31:00  S0007          0
FS0243               24/05/2025 20:31:00  24/05/2025 22:31:00  S0004          0
FS0243               24/05/2025 20:31:00  24/05/2025 22:31:00  S0015          0
FS0243               24/05/2025 20:31:00  24/05/2025 22:31:00  S0008          0
FS0243               24/05/2025 20:31:00  24/05/2025 22:31:00  S0013          0
FS0243               24/05/2025 20:31:00  24/05/2025 22:31:00  S0002          1
*/

BREAK ON StaffID;

SELECT StaffID, LeaveDate, COUNT(StaffID)
FROM Leave
GROUP BY LeaveDate, StaffID
ORDER BY StaffID;

CLEAR BREAKS

-- conflict data ( HAVE LEAVE )
/*
FS0244 - 26/08/2025
FS0243 - 24/05/2025
FS0241 - 23/05/2025 
FS0240 - 23/05/2020
*/

-- make S0002 all Leave become approve  
UPDATE Leave
SET LeaveStatus = 'Approve'
WHERE StaffID = 'S0002';

EXEC staffServe('P0007', 'B0105', 2);