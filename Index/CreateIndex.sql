DROP INDEX uLeaveStatus;
DROP INDEX uCategory;

CREATE INDEX uLeaveStatus ON Leave (UPPER(LeaveStatus));

CREATE INDEX uCategory ON Item (UPPER(Category));
