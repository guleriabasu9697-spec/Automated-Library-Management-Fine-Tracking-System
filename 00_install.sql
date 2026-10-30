-- =============================================================================
-- 00_install.sql  -  Runs the whole project in dependency order.
-- Usage (SQL*Plus / SQLcl, from this directory):   @00_install.sql
-- In SQL Developer: open each file and press F5 (Run Script) in the order below.
-- =============================================================================
SET ECHO OFF
SET SERVEROUTPUT ON SIZE UNLIMITED
@01_schema.sql
@02_seed_data.sql
@03_triggers.sql
@04_pkg_library_mgmt.sql
@05_test_cases.sql
