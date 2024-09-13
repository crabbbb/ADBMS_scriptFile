-- RUN FORMAT
ALTER SESSION SET NLS_DATE_FORMAT = 'DD/MM/YYYY';
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'DD/MM/YYYY HH24:MI:SS';

set linesize 250
set pagesize 100

-- Show every staff schedule on the month including working hours 
-- create become view 
DROP VIEW staffMonthlyWorkingSchedule;

CREATE OR REPLACE VIEW staffMonthlyWorkingSchedule AS 
SELECT s.StaffID, 
    f.FlightScheduleID, 
    f.DepartDateTime - INTERVAL '30' minute AS "CheckIn DateTime", 
    f.ArriveDateTime + INTERVAL '1' hour AS "Expected End DateTime",
    f.DepartDateTime AS "Flight Depart", 
    f.ArriveDateTime AS "Flight Arrive",
    EXTRACT(HOUR FROM ((f.ArriveDateTime + INTERVAL '1' HOUR) - (f.DepartDateTime - INTERVAL '30' MINUTE))) || ' hrs ' || EXTRACT(MINUTE FROM ((f.ArriveDateTime + INTERVAL '1' HOUR) - (f.DepartDateTime - INTERVAL '30' MINUTE))) || ' min' AS "Duration Hours"
FROM FlightSchedule f, StaffSchedule ss, Staff s
WHERE ss.FlightScheduleID = f.FlightScheduleID AND
        ss.StaffID = s.StaffID AND
        TRUNC(f.DepartDateTime, 'MONTH') = TRUNC(SYSDATE, 'MONTH') AND
        TRUNC(f.DepartDateTime, 'YEAR') = TRUNC(SYSDATE, 'YEAR')
ORDER BY s.StaffID, f.DepartDateTime
WITH CHECK OPTION CONSTRAINT chk_monthlyWorkingSchedule;

-- display
COLUMN 'CheckIn DateTime' 	    FORMAT A20 	
COLUMN 'Expected End DateTime' 	FORMAT A20 	
COLUMN 'Flight Depart' 	        FORMAT A20 	
COLUMN 'Flight Arrive' 	        FORMAT A20 	
COLUMN 'Duration Hours'         FORMAT A20

TTITLE LEFT 'STAFF MONTHLY WORKING SCHEDULE';

BREAK ON StaffID;
-- skip 2 is mean \n\n 

SELECT * 
FROM staffMonthlyWorkingSchedule;

CLEAR COLUMNS
CLEAR BREAKS
TTITLE OFF
