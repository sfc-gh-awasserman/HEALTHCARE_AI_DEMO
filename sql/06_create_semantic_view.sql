-- Create Semantic View for Snowflake Intelligence
-- This script creates the semantic view using the YAML specification

USE DATABASE AHF_HEALTHCARE_DEMO;
USE SCHEMA ANALYTICS;

-- Create the semantic view using the YAML specification
-- Note: Replace the file path with the actual path to your YAML file when implementing

/*
-- Upload the YAML file to a stage first
PUT file:///path/to/healthcare_semantic_model.yaml @HEALTHCARE_DATA_STAGE;

-- Create semantic view from YAML
CALL SYSTEM$CREATE_SEMANTIC_VIEW_FROM_YAML(
    'AHF_HEALTHCARE_ANALYTICS_SEMANTIC_VIEW',
    '@HEALTHCARE_DATA_STAGE/healthcare_semantic_model.yaml'
);
*/

-- Alternative: Create semantic view using SQL syntax
CREATE OR REPLACE SEMANTIC VIEW AHF_HEALTHCARE_ANALYTICS_SEMANTIC_VIEW
TABLES (
    AHF_HEALTHCARE_DEMO.ATHENA_EHR.PATIENTS AS patients PRIMARY KEY (PATIENT_ID),
    AHF_HEALTHCARE_DEMO.ATHENA_EHR.ENCOUNTERS AS encounters PRIMARY KEY (ENCOUNTER_ID),
    AHF_HEALTHCARE_DEMO.ATHENA_EHR.APPOINTMENTS AS appointments PRIMARY KEY (APPOINTMENT_ID),
    AHF_HEALTHCARE_DEMO.MCKESSON_PHARMACY.PRESCRIPTIONS AS prescriptions PRIMARY KEY (PRESCRIPTION_ID)
)
RELATIONSHIPS (
    encounters_to_patients AS encounters(PATIENT_ID) REFERENCES patients(PATIENT_ID),
    appointments_to_patients AS appointments(PATIENT_ID) REFERENCES patients(PATIENT_ID),
    prescriptions_to_patients AS prescriptions(PATIENT_ID) REFERENCES patients(PATIENT_ID)
)
DIMENSIONS (
    -- Patient dimensions
    CONCAT(patients.FIRST_NAME, ' ', patients.LAST_NAME) AS patient_name,
    patients.PATIENT_ID AS patient_id,
    DATEDIFF('year', patients.DATE_OF_BIRTH, CURRENT_DATE()) AS patient_age,
    patients.GENDER AS patient_gender,
    patients.CITY AS patient_city,
    patients.STATE AS patient_state,
    patients.PRIMARY_CARE_PROVIDER AS primary_care_provider,
    
    -- Encounter dimensions
    encounters.ENCOUNTER_DATE AS encounter_date,
    DATE_TRUNC('month', encounters.ENCOUNTER_DATE) AS encounter_month,
    DATE_TRUNC('week', encounters.ENCOUNTER_DATE) AS encounter_week,
    encounters.ENCOUNTER_TYPE AS encounter_type,
    encounters.PROVIDER_NAME AS encounter_provider,
    encounters.DIAGNOSIS_DESCRIPTION AS diagnosis,
    encounters.CHIEF_COMPLAINT AS chief_complaint,
    
    -- Appointment dimensions
    appointments.APPOINTMENT_DATE AS appointment_date,
    appointments.APPOINTMENT_TYPE AS appointment_type,
    appointments.STATUS AS appointment_status,
    appointments.PROVIDER_NAME AS appointment_provider,
    
    -- Prescription dimensions
    prescriptions.PRESCRIBED_DATE AS prescribed_date,
    DATE_TRUNC('month', prescriptions.PRESCRIBED_DATE) AS prescribed_month,
    prescriptions.PICKUP_STATUS AS pickup_status,
    prescriptions.MEDICATION_NAME AS medication_name,
    prescriptions.MEDICATION_STRENGTH AS medication_strength,
    prescriptions.PHARMACY_LOCATION AS pharmacy_location,
    prescriptions.PRESCRIBER_NAME AS prescriber_name
)
METRICS (
    -- Encounter metrics
    COUNT(encounters.ENCOUNTER_ID) AS total_encounters,
    COUNT(DISTINCT encounters.PATIENT_ID) AS unique_patients_with_encounters,
    AVG(encounters.VISIT_DURATION_MINUTES) AS avg_visit_duration_minutes,
    COUNT(CASE WHEN encounters.FOLLOW_UP_NEEDED = TRUE THEN 1 END) AS encounters_needing_followup,
    
    -- Prescription metrics
    COUNT(prescriptions.PRESCRIPTION_ID) AS total_prescriptions,
    COUNT(CASE WHEN prescriptions.PICKUP_STATUS = 'Not Picked Up' THEN 1 END) AS unpicked_prescriptions,
    COUNT(CASE WHEN prescriptions.PICKUP_STATUS = 'Picked Up' THEN 1 END) AS picked_up_prescriptions,
    ROUND((COUNT(CASE WHEN prescriptions.PICKUP_STATUS = 'Picked Up' THEN 1 END) * 100.0 / NULLIF(COUNT(prescriptions.PRESCRIPTION_ID), 0)), 2) AS prescription_adherence_rate,
    
    -- Appointment metrics
    COUNT(appointments.APPOINTMENT_ID) AS total_appointments,
    COUNT(CASE WHEN appointments.APPOINTMENT_DATE >= CURRENT_DATE() AND appointments.STATUS = 'Scheduled' THEN 1 END) AS upcoming_appointments,
    
    -- Patient metrics
    COUNT(DISTINCT patients.PATIENT_ID) AS unique_patients,
    
    -- Combined metrics for at-risk analysis
    COUNT(CASE WHEN prescriptions.PICKUP_STATUS = 'Not Picked Up' 
               AND prescriptions.PRESCRIBED_DATE >= DATEADD('month', -2, CURRENT_DATE())
               AND NOT EXISTS (
                   SELECT 1 FROM AHF_HEALTHCARE_DEMO.ATHENA_EHR.APPOINTMENTS a 
                   WHERE a.PATIENT_ID = prescriptions.PATIENT_ID 
                   AND a.APPOINTMENT_DATE >= CURRENT_DATE() 
                   AND a.STATUS = 'Scheduled'
               ) THEN 1 END) AS at_risk_patients
);

-- Grant necessary permissions for the semantic view
-- GRANT SELECT ON AHF_HEALTHCARE_ANALYTICS_SEMANTIC_VIEW TO ROLE ANALYST_ROLE;

-- Verify the semantic view was created successfully
DESCRIBE SEMANTIC VIEW AHF_HEALTHCARE_ANALYTICS_SEMANTIC_VIEW;

COMMENT = 'Semantic view created for Snowflake Intelligence healthcare analytics';
