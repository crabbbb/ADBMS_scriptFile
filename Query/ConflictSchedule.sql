-- the flightschedule which have staff can't attend
-- when assign already but go to apply leave, and the leave have been approved 

CREATE OR REPLACE VIEW conflictSchedule AS 
SELECT f1.FlightScheduleID, 
        f1.DepartDateTime, 
        f1.ArriveDateTime,
        (SELECT COUNT(*)
                FROM StaffSchedule s3
                WHERE s3.FlightScheduleID = f1.FlightScheduleID) -
        (SELECT COUNT(s2.StaffID)
                FROM FlightSchedule f2, StaffSchedule ss2, Staff s2, Leave l2
                WHERE ss2.FlightScheduleID = f2.FlightScheduleID AND
                        ss2.StaffID = s2.StaffID AND
                        s2.StaffID = l2.StaffID AND
                        TRUNC(l2.LeaveDate) = TRUNC(f2.DepartDateTime) AND
                        UPPER(l2.LeaveStatus) = 'APPROVE' AND
                        f2.FlightScheduleID = f1.FlightScheduleID) AS "Available",  
        (SELECT COUNT(s2.StaffID)
                FROM FlightSchedule f2, StaffSchedule ss2, Staff s2, Leave l2
                WHERE ss2.FlightScheduleID = f2.FlightScheduleID AND
                        ss2.StaffID = s2.StaffID AND
                        s2.StaffID = l2.StaffID AND
                        TRUNC(l2.LeaveDate) = TRUNC(f2.DepartDateTime) AND
                        UPPER(l2.LeaveStatus) = 'APPROVE' AND
                        f2.FlightScheduleID = f1.FlightScheduleID) AS "NotAvailable"
FROM FlightSchedule f1, StaffSchedule ss1, Staff s1, Leave l1
WHERE ss1.FlightScheduleID = f1.FlightScheduleID AND
        ss1.StaffID = s1.StaffID AND
        s1.StaffID = l1.StaffID AND
        TRUNC(l1.LeaveDate) = TRUNC(f1.DepartDateTime) AND
        NOT UPPER(l1.LeaveStatus) = 'REJECT'
GROUP BY f1.FlightScheduleID, f1.DepartDateTime, f1.ArriveDateTime
ORDER BY f1.FlightScheduleID
WITH CHECK OPTION CONSTRAINT chk_conflictSchedule;


COLUMN DepartDateTime           FORMAT A20 	
COLUMN ArriveDateTime           FORMAT A20 	
COLUMN FlightScheduleID         FORMAT A20 

TTITLE LEFT 'FLIGHT SCHEDULE THAT HAVE STAFF CANNOT ATTEND';

BREAK ON StaffID;

SELECT * 
FROM conflictSchedule;

CLEAR COLUMNS
CLEAR BREAKS
TTITLE OFF


-- set some conflict data 
/*
FS0244 - 26/08/2025
FS0243 - 24/05/2025
FS0241 - 23/05/2025 
FS0240 - 23/05/2020
*/

-- FS0244
INSERT INTO Leave (LeaveID, LeaveDate, LeaveReason, LeaveStatus, StaffID) VALUES ('L' || TO_CHAR(leave_seq.nextval, 'FM0000'), '26/08/2025', 'Family Emergency', 'Approve', 'S0007');
INSERT INTO Leave (LeaveID, LeaveDate, LeaveReason, LeaveStatus, StaffID) VALUES ('L' || TO_CHAR(leave_seq.nextval, 'FM0000'), '26/08/2025', 'Family Emergency', 'Approve', 'S0001');

-- FS0243
INSERT INTO Leave (LeaveID, LeaveDate, LeaveReason, LeaveStatus, StaffID) VALUES ('L' || TO_CHAR(leave_seq.nextval, 'FM0000'), '24/05/2025', 'Family Emergency', 'Approve', 'S0002');

-- FS0241
INSERT INTO Leave (LeaveID, LeaveDate, LeaveReason, LeaveStatus, StaffID) VALUES ('L' || TO_CHAR(leave_seq.nextval, 'FM0000'), '23/05/2025', 'Family Emergency', 'Approve', 'S0012');
INSERT INTO Leave (LeaveID, LeaveDate, LeaveReason, LeaveStatus, StaffID) VALUES ('L' || TO_CHAR(leave_seq.nextval, 'FM0000'), '23/05/2025', 'Family Emergency', 'Approve', 'S0013');


/*
RESULT :

FLIGHTSCHEDULEID     DEPARTDATETIME       ARRIVEDATETIME        Available Not Available
-------------------- -------------------- -------------------- ---------- -------------
FS0241               23/05/2025 17:46:00  23/05/2025 18:46:00           4             2
FS0243               24/05/2025 20:31:00  24/05/2025 22:31:00           5             1
FS0244               26/08/2025 18:31:00  26/08/2025 19:31:00           4             2
*/

