CREATE OR REPLACE FUNCTION up_metadata( id numeric , f VARCHAR(30), v VARCHAR(100)) RETURNS VOID AS 
$$
BEGIN
    LOOP
        UPDATE metadata SET value = v  WHERE isdid = id AND fieldname = f;

        IF found THEN 
            RETURN;
        END IF;

        BEGIN
            INSERT INTO metadata (isdid, fieldname, value) VALUES (id,f,v);
            RETURN;
        EXCEPTION WHEN unique_violation THEN

        END;
    END LOOP;
END;
$$
LANGUAGE plpgsql;


DROP TABLE IF EXISTS TEMP_SEQUENCE;
CREATE TABLE TEMP_SEQUENCE (
    isdid numeric REFERENCES sequence (isdid),
    c_type VARCHAR(11)
);



DROP TRIGGER IF EXISTS classification_sequence on SEQUENCE; 

CREATE OR REPLACE FUNCTION up_temp_sequence() RETURNS TRIGGER AS  $classification_sequence$
BEGIN
        IF(TG_OP='INSERT') THEN
            INSERT INTO TEST_SEQUENCE (isdid) VALUES (NEW.isdid);
        END IF;

        IF(TG_OP='UPDATE') THEN 
            INSERT INTO TEST_SEQUENCE (isdid) VALUES (OLD.isdid);
        END IF;

        IF(TG_OP='DELETE') THEN
            DELETE FROM TEST_SEQUENCE WHERE isdid = OLD.isdid;
    END IF;
END;
$classification_sequence$ LANGUAGE plpgsql; 

CREATE TRIGGER classification_sequence AFTER INSERT OR UPDATE OR DELETE ON SEQUENCE FOR EACH ROW EXECUTE PROCEDURE up_temp_sequence();

GRANT ALL PRIVILEGES ON TEMP_SEQUENCE TO PUBLIC;
