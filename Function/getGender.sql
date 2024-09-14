CREATE OR REPLACE FUNCTION getGender(gender IN VARCHAR2) RETURN VARCHAR2 IS 
BEGIN 
	RETURN CASE WHEN UPPER(gender) = 'M' THEN 'MALE' ELSE 'FEMALE' END;
END;
/