/*
    Function that returns the most popular `n` destinations (`n` is the function argument),
    ordered by the number of tourists that are going to visit them, as well as the number of tourists
    that have made reservations. A destination is considered popular if there are at least 5 tourists
    that have made a booking to visit it.
*/
CREATE OR REPLACE FUNCTION TRENDING_DESTINATIONS(n IN PLS_INTEGER) RETURN SYS_REFCURSOR
IS
    v_cursor SYS_REFCURSOR;
BEGIN
    OPEN v_cursor FOR
        SELECT D.NAME || ', ' || D.COUNTRY, COUNT(*)
        FROM JOURNEYS J JOIN DESTINATIONS D ON J.DESTINATION_ID = D.ID
        WHERE J.START_DATE > SYSDATE
        GROUP BY D.NAME, D.COUNTRY
        HAVING COUNT(*) >= 5
        ORDER BY COUNT(*) DESC
        FETCH FIRST n ROWS ONLY;
    RETURN v_cursor;
END TRENDING_DESTINATIONS;

/*
    Trigger that inserts a new row in the HISTORY table whenever the finish date of a tour has passed.
    The trigger also deletes the record from the JOURNEYS table.
*/
CREATE OR REPLACE TRIGGER JOURNEYS_FINISHED
AFTER INSERT OR UPDATE ON JOURNEYS
FOR EACH ROW
DECLARE
    tourist_name TOURISTS.NAME%TYPE;
    tourist_surname TOURISTS.SURNAME%TYPE;
    destination_name DESTINATIONS.NAME%TYPE;
    destination_country DESTINATIONS.COUNTRY%TYPE;
BEGIN
    IF :NEW.FINISH_DATE <= TO_DATE(TO_CHAR(SYSDATE, 'YYYY-MM-DD'), 'YYYY-MM-DD') THEN
        SELECT NAME, SURNAME INTO tourist_name, tourist_surname FROM TOURISTS WHERE ID = :NEW.TOURIST_ID;
        SELECT NAME, COUNTRY INTO destination_name, destination_country FROM DESTINATIONS WHERE ID = :NEW.DESTINATION_ID;
        IF UPDATING THEN
            INSERT INTO HISTORY VALUES(:OLD.TOURIST_ID, tourist_name, tourist_surname, destination_name, destination_country, :OLD.START_DATE, :OLD.FINISH_DATE);
        ELSE
            INSERT INTO HISTORY VALUES(:NEW.TOURIST_ID, tourist_name, tourist_surname, destination_name, destination_country, :NEW.START_DATE, :NEW.FINISH_DATE);
        END IF;
    END IF;
END JOURNEYS_FINISHED;

/*
    Procedure that deletes all journeys that have finished from the JOURNEYS table.
*/
CREATE OR REPLACE PROCEDURE DELETE_JOURNEY
IS
BEGIN
    DELETE FROM JOURNEY_ACTIVITIES WHERE JOURNEY_ID IN (SELECT A.JOURNEY_ID FROM JOURNEYS A WHERE A.FINISH_DATE < SYSDATE);
    DELETE FROM JOURNEYS WHERE FINISH_DATE < SYSDATE;
END DELETE_JOURNEY;

/*
    Mechanism that deletes all journeys that have finished, by creating a job that does this daily.
    (there is no need to do this more frequently, since the dates of the journeys are stored with a
    precision of 1 day)
*/
BEGIN
    DBMS_SCHEDULER.CREATE_JOB(
        job_name => 'DELETE_JOURNEY_JOB',
        job_type => 'STORED_PROCEDURE',
        job_action => 'DELETE_JOURNEY',
        start_date => SYSDATE,
        repeat_interval => 'FREQ=DAILY;INTERVAL=1',
        enabled => TRUE
    );
    DBMS_SCHEDULER.RUN_JOB('DELETE_JOURNEY_JOB');
END;
/

/*
    Helper function that determines a traveller's gender based on his name (the function works only for Greek travellers).
*/
CREATE OR REPLACE FUNCTION GET_GENDER(traveller_name IN VARCHAR2) RETURN VARCHAR2
IS
    end_letters VARCHAR2(5); -- Greek letters take up 2 bytes each
    is_male BOOLEAN;
    is_female BOOLEAN;
BEGIN
    IF traveller_name IS NOT NULL AND LENGTH(traveller_name) >= 2 THEN
        end_letters := SUBSTR(traveller_name, -2, 2); -- in Greek, we need just the last two letters to determine the gender
    ELSE
        end_letters := traveller_name;
    END IF;
    
    IF end_letters IS NULL THEN
        RETURN 'Error: traveller name is null';
    ELSE
        is_male := CASE WHEN end_letters IN ('ος', 'ης', 'ας', 'ων', 'ός', 'ής', 'άς', 'ών') THEN TRUE ELSE FALSE END;
        is_female := CASE WHEN SUBSTR(end_letters, 2, 1) IN ('α', 'η', 'ω', 'ά', 'ή', 'ού', 'ώ') THEN TRUE ELSE FALSE END;

        IF is_male OR traveller_name = 'Άδωνις' THEN
            RETURN 'Male';
        ELSIF is_female OR traveller_name = 'Άρτεμις' OR traveller_name = 'Ελισάβετ' THEN
            RETURN 'Female';
        ELSE
            RETURN 'Error: traveller name is not Greek or is some exception to these rules';
        END IF;
    END IF;
END GET_GENDER;

/*
    Function that determines the destinations that were least visited by women last year, ordered by
    the number of female tourists that have visited them.
    The function takes as input the number `n` of destinations to be returned.
*/
CREATE OR REPLACE FUNCTION LEAST_VISITED_DESTINATIONS_WOMEN(n IN NUMBER) RETURN SYS_REFCURSOR
IS
    v_cursor SYS_REFCURSOR;
BEGIN
    OPEN v_cursor FOR
        SELECT D.NAME || ', ' || D.COUNTRY, COUNT(DISTINCT J.TOURIST_ID)
        FROM HISTORY J JOIN TOURISTS T ON J.TOURIST_ID = T.ID
                       JOIN DESTINATIONS D ON (J.DESTINATION_NAME = D.NAME AND J.DESTINATION_COUNTRY = D.COUNTRY)
        WHERE EXTRACT(YEAR FROM J.START_DATE) = EXTRACT(YEAR FROM SYSDATE) - 1
        GROUP BY D.NAME, D.COUNTRY
        ORDER BY (SELECT COUNT(DISTINCT H.TOURIST_ID)
                  FROM HISTORY H JOIN TOURISTS A ON H.TOURIST_ID = A.ID
                  WHERE H.DESTINATION_NAME = D.NAME AND H.DESTINATION_COUNTRY = D.COUNTRY
                        AND EXTRACT(YEAR FROM H.START_DATE) = EXTRACT(YEAR FROM SYSDATE) - 1 AND GET_GENDER(A.NAME) = 'Female')
        FETCH FIRST n ROWS ONLY;
    RETURN v_cursor;
END LEAST_VISITED_DESTINATIONS_WOMEN;