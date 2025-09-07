-- Load Sample Data into Healthcare Demo Tables
-- This script loads the CSV sample data into the Snowflake tables

USE DATABASE AHF_HEALTHCARE_DEMO;

-- Load AthenaHealth patient data
USE SCHEMA ATHENA_EHR;

-- Note: In a real implementation, you would use PUT commands to upload files to the stage
-- PUT file:///path/to/athena_patients.csv @HEALTHCARE_DATA_STAGE;
-- PUT file:///path/to/athena_encounters.csv @HEALTHCARE_DATA_STAGE;
-- PUT file:///path/to/athena_appointments.csv @HEALTHCARE_DATA_STAGE;

-- For demo purposes, we'll use COPY INTO with sample data
-- Replace these with actual file paths when implementing

/*
COPY INTO PATIENTS
FROM @HEALTHCARE_DATA_STAGE/athena_patients.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

COPY INTO ENCOUNTERS
FROM @HEALTHCARE_DATA_STAGE/athena_encounters.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

COPY INTO APPOINTMENTS
FROM @HEALTHCARE_DATA_STAGE/athena_appointments.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';
*/

-- Load McKesson pharmacy data
USE SCHEMA MCKESSON_PHARMACY;

-- Note: In a real implementation, you would use PUT commands to upload files to the stage
-- PUT file:///path/to/mckesson_prescriptions.csv @HEALTHCARE_DATA_STAGE;
-- PUT file:///path/to/mckesson_pharmacy_locations.csv @HEALTHCARE_DATA_STAGE;

/*
COPY INTO PHARMACY_LOCATIONS
FROM @HEALTHCARE_DATA_STAGE/mckesson_pharmacy_locations.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';

COPY INTO PRESCRIPTIONS
FROM @HEALTHCARE_DATA_STAGE/mckesson_prescriptions.csv
FILE_FORMAT = CSV_FORMAT
ON_ERROR = 'CONTINUE';
*/

-- Verify data loading
SELECT 'PATIENTS' AS TABLE_NAME, COUNT(*) AS RECORD_COUNT FROM AHF_HEALTHCARE_DEMO.ATHENA_EHR.PATIENTS
UNION ALL
SELECT 'ENCOUNTERS' AS TABLE_NAME, COUNT(*) AS RECORD_COUNT FROM AHF_HEALTHCARE_DEMO.ATHENA_EHR.ENCOUNTERS
UNION ALL
SELECT 'APPOINTMENTS' AS TABLE_NAME, COUNT(*) AS RECORD_COUNT FROM AHF_HEALTHCARE_DEMO.ATHENA_EHR.APPOINTMENTS
UNION ALL
SELECT 'PRESCRIPTIONS' AS TABLE_NAME, COUNT(*) AS RECORD_COUNT FROM AHF_HEALTHCARE_DEMO.MCKESSON_PHARMACY.PRESCRIPTIONS
UNION ALL
SELECT 'PHARMACY_LOCATIONS' AS TABLE_NAME, COUNT(*) AS RECORD_COUNT FROM AHF_HEALTHCARE_DEMO.MCKESSON_PHARMACY.PHARMACY_LOCATIONS;

COMMENT = 'Sample data loading script prepared';
