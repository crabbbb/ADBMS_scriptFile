ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'DD/MM/YYYY HH24:MI:SS';

DROP trigger trg_staffSchedule;

-- Action should do 


CREATE OR REPLACE TRIGGER trg_staffSchedule 
BEFORE INSERT OR UPDATE ON STAFFSCHEDULE
FOR EACH ROW

DECLARE

startDate FlightSchedule.DepartDateTime%TYPE;
endDate FlightSchedule.ArriveDateTime%TYPE;
leaveNo NUMBER(2);

BEGIN

-- get the date duration 
SELECT TRUNC(DepartDateTime), TRUNC(ArriveDateTime) INTO startDate, endDate
FROM FlightSchedule
WHERE FlightScheduleID = :NEW.FlightScheduleID;

SELECT COUNT(*) INTO leaveNo
FROM Leave
WHERE StaffID = :NEW.StaffID AND
        (LeaveDate BETWEEN startDate AND endDate) AND
        (UPPER(LeaveStatus) = 'PENDING' OR UPPER(LeaveStatus) = 'APPROVE');

IF (leaveNo > 0) THEN 
        -- have take leave cannot on duty 
        RAISE_APPLICATION_ERROR(-20000, 'Staff ' || :NEW.StaffID || ' have leave is on pending or already been approved. You are not able to adding he/she into this schedule');
END IF;

END;
/

-- INSERT FlightSchedule TO HAVE THIS SCHEDULE 
-- DATE = 09/01/2023
-- Flight = FS0001

-- this is test for STATUS IN APPROVE
-- staff = S0005
UPDATE Leave
SET LeaveStatus = 'Approve', LeaveDate = '09/01/2023'
WHERE LeaveID = 'L0001';

-- STAFFSCHEDULE FOR TESTING CONFLICT ( WILL NOT ABLE TO BE ADDED )
INSERT INTO StaffSchedule (FlightScheduleID, StaffID, WorkingHours, CheckIn, CheckOut) 
        VALUES ('FS0001', 'S0005', '6', '09/01/2025 19:25:00', '09/01/2025 01:25:00');

-- this is test for STATUS IN PENDING
UPDATE Leave
SET LeaveStatus = 'Pending', LeaveDate = '09/01/2023'
WHERE LeaveID = 'L0001';

-- this is test for STATUS IN REJECT
UPDATE Leave
SET LeaveStatus = 'Reject', LeaveDate = '09/01/2023'
WHERE LeaveID = 'L0001';




-- testing 
SELECT * 
FROM FlightSchedule
WHERE FlightScheduleID = 'FS0245';

SELECT * 
FROM Leave
WHERE LeaveID = 'L0201';

DELETE FROM FlightSchedule
WHERE FlightScheduleID = 'FS0245';

DELETE FROM Leave
WHERE LeaveID = 'L0201';









-- NOTE
-- get date only from timestamp
SELECT TO_CHAR(CAST(DepartDateTime AS DATE), 'DD/MM/YYYY')
FROM FlightRoute;

-- OR --

SELECT TRUNC(DepartDateTime) AS DepartDate
FROM FlightRoute;

-- check in leave date in between the flight route startDate and endDate
SELECT COUNT(*)
FROM FlightRoute fr, StaffSchedule ss