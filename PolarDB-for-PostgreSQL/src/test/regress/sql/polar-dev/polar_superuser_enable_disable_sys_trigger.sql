-- create superuser
CREATE USER polar_su SUPERUSER;
\c - polar_su;
-- create polar_superuser
CREATE USER polar_psu POLAR_SUPERUSER;
\c - polar_psu;
-- create regular user
CREATE USER polar_u;
\c - polar_u;
--
-- regular user create tables and triggers
--
\c - polar_u;
DROP TABLE IF EXISTS test_table_c3;
DROP TABLE IF EXISTS test_table_c2;
DROP TABLE IF EXISTS test_table_c1;
DROP TABLE IF EXISTS test_table;
DROP FUNCTION IF EXISTS test_procedure;
CREATE TABLE test_table(id INT, pid INT, name TEXT) PARTITION BY RANGE(id);
CREATE TABLE test_table_c1 PARTITION OF test_table FOR VALUES FROM (1) TO (100);
CREATE TABLE test_table_c2 PARTITION OF test_table FOR VALUES FROM (100) TO (200);
CREATE TABLE test_table_c3 PARTITION OF test_table FOR VALUES FROM (200) TO (300);
CREATE OR REPLACE FUNCTION test_procedure() RETURNS TRIGGER AS $$
BEGIN
	RETURN new;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER test_trigger AFTER INSERT OR UPDATE OR DELETE ON test_table
FOR EACH ROW
EXECUTE PROCEDURE test_procedure();
-- regular user enable/disable triggers, it should fail for system trigger
\c - polar_u;
ALTER TABLE test_table ENABLE ALWAYS TRIGGER test_trigger;
ALTER TABLE test_table DISABLE TRIGGER test_trigger;
ALTER TABLE test_table ENABLE TRIGGER test_trigger;
-- polar superuser enable/disable triggers, it should succ
\c - polar_psu;
ALTER TABLE test_table ENABLE ALWAYS TRIGGER test_trigger;
ALTER TABLE test_table DISABLE TRIGGER test_trigger;
ALTER TABLE test_table ENABLE TRIGGER test_trigger;
-- superuser enable/disable triggers, it should succ
\c - polar_su;
ALTER TABLE test_table ENABLE ALWAYS TRIGGER test_trigger;
ALTER TABLE test_table DISABLE TRIGGER test_trigger;
ALTER TABLE test_table ENABLE TRIGGER test_trigger;
--
-- polar_superuser create tables and triggers
--
\c - polar_u;
DROP TABLE IF EXISTS test_table_c3;
DROP TABLE IF EXISTS test_table_c2;
DROP TABLE IF EXISTS test_table_c1;
DROP TABLE IF EXISTS test_table;
DROP FUNCTION IF EXISTS test_procedure;
\c - polar_psu;
CREATE TABLE test_table(id INT, pid INT, name TEXT) PARTITION BY RANGE(id);
CREATE TABLE test_table_c1 PARTITION OF test_table FOR VALUES FROM (1) TO (100);
CREATE TABLE test_table_c2 PARTITION OF test_table FOR VALUES FROM (100) TO (200);
CREATE TABLE test_table_c3 PARTITION OF test_table FOR VALUES FROM (200) TO (300);
CREATE OR REPLACE FUNCTION test_procedure() RETURNS TRIGGER AS $$
BEGIN
	RETURN new;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER test_trigger AFTER INSERT OR UPDATE OR DELETE ON test_table
FOR EACH ROW
EXECUTE PROCEDURE test_procedure();
-- regular user enable/disable triggers, it should fail for table's owner check
\c - polar_u;
ALTER TABLE test_table ENABLE ALWAYS TRIGGER test_trigger;
ALTER TABLE test_table DISABLE TRIGGER test_trigger;
ALTER TABLE test_table ENABLE TRIGGER test_trigger;
-- polar superuser enable/disable triggers, it should succ
\c - polar_psu;
ALTER TABLE test_table ENABLE ALWAYS TRIGGER test_trigger;
ALTER TABLE test_table DISABLE TRIGGER test_trigger;
ALTER TABLE test_table ENABLE TRIGGER test_trigger;
-- superuser enable/disable triggers, it should succ
\c - polar_su;
ALTER TABLE test_table ENABLE ALWAYS TRIGGER test_trigger;
ALTER TABLE test_table DISABLE TRIGGER test_trigger;
ALTER TABLE test_table ENABLE TRIGGER test_trigger;
--
-- polar_superuser create tables and triggers
--
\c - polar_psu;
DROP TABLE IF EXISTS test_table_c3;
DROP TABLE IF EXISTS test_table_c2;
DROP TABLE IF EXISTS test_table_c1;
DROP TABLE IF EXISTS test_table;
DROP FUNCTION IF EXISTS test_procedure;
\c - polar_su;
CREATE TABLE test_table(id INT, pid INT, name TEXT) PARTITION BY RANGE(id);
CREATE TABLE test_table_c1 PARTITION OF test_table FOR VALUES FROM (1) TO (100);
CREATE TABLE test_table_c2 PARTITION OF test_table FOR VALUES FROM (100) TO (200);
CREATE TABLE test_table_c3 PARTITION OF test_table FOR VALUES FROM (200) TO (300);
CREATE OR REPLACE FUNCTION test_procedure() RETURNS TRIGGER AS $$
BEGIN
	RETURN new;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER test_trigger AFTER INSERT OR UPDATE OR DELETE ON test_table
FOR EACH ROW
EXECUTE PROCEDURE test_procedure();
-- regular user enable/disable triggers, it should fail for table's owner check
\c - polar_u;
ALTER TABLE test_table ENABLE ALWAYS TRIGGER test_trigger;
ALTER TABLE test_table DISABLE TRIGGER test_trigger;
ALTER TABLE test_table ENABLE TRIGGER test_trigger;
-- polar superuser enable/disable triggers, it should fail for table's owner check
\c - polar_psu;
ALTER TABLE test_table ENABLE ALWAYS TRIGGER test_trigger;
ALTER TABLE test_table DISABLE TRIGGER test_trigger;
ALTER TABLE test_table ENABLE TRIGGER test_trigger;
-- superuser enable/disable triggers, it should succ
\c - polar_su;
ALTER TABLE test_table ENABLE ALWAYS TRIGGER test_trigger;
ALTER TABLE test_table DISABLE TRIGGER test_trigger;
ALTER TABLE test_table ENABLE TRIGGER test_trigger;
--
-- clean up
--
\c - polar_su;
DROP TABLE IF EXISTS test_table_c3;
DROP TABLE IF EXISTS test_table_c2;
DROP TABLE IF EXISTS test_table_c1;
DROP TABLE IF EXISTS test_table;
DROP FUNCTION IF EXISTS test_procedure;
DROP USER polar_psu;
DROP USER polar_u;