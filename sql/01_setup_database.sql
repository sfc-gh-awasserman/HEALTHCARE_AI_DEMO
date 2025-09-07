-- Snowflake Intelligence Healthcare Demo Setup
-- Database and Schema Creation for Aids Healthcare Foundation Demo

-- Create database for the healthcare demo
CREATE DATABASE IF NOT EXISTS AHF_HEALTHCARE_DEMO;
USE DATABASE AHF_HEALTHCARE_DEMO;

-- Create schemas for different data sources
CREATE SCHEMA IF NOT EXISTS ATHENA_EHR;
CREATE SCHEMA IF NOT EXISTS MCKESSON_PHARMACY;
CREATE SCHEMA IF NOT EXISTS ANALYTICS;

-- Set up file format for CSV loading
CREATE OR REPLACE FILE FORMAT CSV_FORMAT
  TYPE = 'CSV'
  FIELD_DELIMITER = ','
  RECORD_DELIMITER = '\n'
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  TRIM_SPACE = TRUE
  ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE
  ESCAPE = 'NONE'
  ESCAPE_UNENCLOSED_FIELD = '\134'
  DATE_FORMAT = 'YYYY-MM-DD'
  TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS'
  NULL_IF = ('NULL', 'null', '', 'N/A', 'n/a');

-- Create internal stage for data loading
CREATE OR REPLACE STAGE HEALTHCARE_DATA_STAGE
  FILE_FORMAT = CSV_FORMAT;

-- Create warehouse for demo (adjust size as needed)
CREATE OR REPLACE WAREHOUSE AHF_DEMO_WH
  WITH 
    WAREHOUSE_SIZE = 'SMALL'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 1
    SCALING_POLICY = 'STANDARD'
    COMMENT = 'Warehouse for AHF Healthcare Demo';

COMMENT = 'Setup complete for AHF Healthcare Demo database and schemas';
