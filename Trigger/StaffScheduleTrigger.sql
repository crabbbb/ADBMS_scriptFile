ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'DD/MM/YYYY HH24:MI:SS';

DROP trigger trg_staffSchedule;

-- Action should do 


CREATE OR REPLACE TRIGGER trg_staffSchedule 
BEFORE INSERT OR UPDATE ON STAFFSCHEDULE
FOR EACH ROW

DECLARE

startDate DATE;
endDate DATE;
leaveNo NUMBER(2);

BEGIN

-- get the date duration 
SELECT TRUNC(DepartDateTime), TRUNC(ArriveDateTime) INTO startDate, endDate
FROM FlightRoute
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

-- testing 
DELETE FROM FlightRoute
WHERE FlightScheduleID = 'FS0001' AND
        AirportID = 'A0007';

DELETE FROM Leave
WHERE LeaveID = 'L0021';

-- INSERT FlightRoute TO HAVE THIS SCHEDULE 
-- DATE = 6/9/2024
INSERT INTO FlightRoute (FlightScheduleID, AirportID, DepartDateTime, ArriveDateTime, FlightDuration) VALUES ('FS0001', 'A0007', '6/9/2024 20:53', NULL, '3');

-- this is test for STATUS IN APPROVE
INSERT INTO Leave (LeaveID, LeaveDate, LeaveReason, LeaveStatus, StaffID) VALUES ('L' || TO_CHAR(leave_seq.nextval, 'FM0000'), '6/9/2024', 'Dental Emergencies', 'Approve', 'S0005');

-- this is test for STATUS IN PENDING
INSERT INTO Leave (LeaveID, LeaveDate, LeaveReason, LeaveStatus, StaffID) VALUES ('L' || TO_CHAR(leave_seq.nextval, 'FM0000'), '6/9/2024', 'Dental Emergencies', 'Pending', 'S0005');

-- this is test for STATUS IN REJECT
INSERT INTO Leave (LeaveID, LeaveDate, LeaveReason, LeaveStatus, StaffID) VALUES ('L' || TO_CHAR(leave_seq.nextval, 'FM0000'), '6/9/2024', 'Dental Emergencies', 'Reject', 'S0005');





INSERT INTO StaffSchedule (FlightScheduleID, StaffID, WorkingHours, CheckIn, CheckOut) VALUES ('FS0001', 'S0013', '6', '30/06/2023', '30/06/2023');

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