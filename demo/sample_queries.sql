-- Sample Queries for Snowflake Intelligence Healthcare Demo
-- These queries demonstrate the capabilities of the healthcare analytics agent

USE DATABASE AHF_HEALTHCARE_DEMO;
USE SCHEMA ANALYTICS;

-- ============================================================================
-- DEMO QUERY 1: Patient Encounters Overview
-- ============================================================================

-- Natural language query for the agent:
-- "Show me our patient encounters per day for the last month"

-- Equivalent SQL query for reference:
SELECT 
    encounter_date,
    total_encounters,
    unique_patients_with_encounters,
    avg_visit_duration_minutes,
    encounters_needing_followup
FROM (
    SELECT 
        encounter_date,
        COUNT(*) as total_encounters,
        COUNT(DISTINCT patient_id) as unique_patients_with_encounters,
        ROUND(AVG(visit_duration_minutes), 1) as avg_visit_duration_minutes,
        SUM(CASE WHEN follow_up_needed = TRUE THEN 1 ELSE 0 END) as encounters_needing_followup
    FROM AHF_HEALTHCARE_DEMO.ATHENA_EHR.ENCOUNTERS
    WHERE encounter_date >= DATEADD('month', -1, CURRENT_DATE())
    GROUP BY encounter_date
    ORDER BY encounter_date DESC
);

-- ============================================================================
-- DEMO QUERY 2: At-Risk Patients Identification
-- ============================================================================

-- Natural language query for the agent:
-- "Show me patients that haven't picked up their prescription for the last two months and don't have an upcoming appointment"

-- Equivalent SQL query for reference:
SELECT 
    p.patient_id,
    p.first_name,
    p.last_name,
    p.phone,
    p.email,
    p.primary_care_provider,
    pr.medication_name,
    pr.prescribed_date,
    pr.pharmacy_location,
    DATEDIFF('day', pr.prescribed_date, CURRENT_DATE()) as days_since_prescribed,
    -- Check for upcoming appointments
    CASE WHEN a.appointment_date IS NOT NULL 
         THEN 'Has upcoming appointment on ' || a.appointment_date::VARCHAR
         ELSE 'No upcoming appointments' 
    END as appointment_status
FROM AHF_HEALTHCARE_DEMO.ATHENA_EHR.PATIENTS p
INNER JOIN AHF_HEALTHCARE_DEMO.MCKESSON_PHARMACY.PRESCRIPTIONS pr 
    ON p.patient_id = pr.patient_id
LEFT JOIN (
    SELECT patient_id, MIN(appointment_date) as appointment_date
    FROM AHF_HEALTHCARE_DEMO.ATHENA_EHR.APPOINTMENTS
    WHERE appointment_date >= CURRENT_DATE() 
    AND status = 'Scheduled'
    GROUP BY patient_id
) a ON p.patient_id = a.patient_id
WHERE pr.pickup_status = 'Not Picked Up'
  AND pr.prescribed_date >= DATEADD('month', -2, CURRENT_DATE())
  AND a.appointment_date IS NULL
ORDER BY pr.prescribed_date ASC;

-- ============================================================================
-- DEMO QUERY 3: Clinical Notes Summary
-- ============================================================================

-- Natural language query for the agent:
-- "Summarize the clinical notes for these patients over their last few appointments"

-- Equivalent SQL query for reference (for the at-risk patients):
WITH at_risk_patients AS (
    SELECT DISTINCT p.patient_id, p.first_name, p.last_name
    FROM AHF_HEALTHCARE_DEMO.ATHENA_EHR.PATIENTS p
    INNER JOIN AHF_HEALTHCARE_DEMO.MCKESSON_PHARMACY.PRESCRIPTIONS pr 
        ON p.patient_id = pr.patient_id
    LEFT JOIN (
        SELECT patient_id, MIN(appointment_date) as appointment_date
        FROM AHF_HEALTHCARE_DEMO.ATHENA_EHR.APPOINTMENTS
        WHERE appointment_date >= CURRENT_DATE() 
        AND status = 'Scheduled'
        GROUP BY patient_id
    ) a ON p.patient_id = a.patient_id
    WHERE pr.pickup_status = 'Not Picked Up'
      AND pr.prescribed_date >= DATEADD('month', -2, CURRENT_DATE())
      AND a.appointment_date IS NULL
)
SELECT 
    arp.patient_id,
    arp.first_name,
    arp.last_name,
    e.encounter_date,
    e.encounter_type,
    e.provider_name,
    e.chief_complaint,
    e.diagnosis_description,
    e.clinical_notes,
    e.follow_up_needed
FROM at_risk_patients arp
INNER JOIN AHF_HEALTHCARE_DEMO.ATHENA_EHR.ENCOUNTERS e 
    ON arp.patient_id = e.patient_id
WHERE e.encounter_date >= DATEADD('month', -3, CURRENT_DATE())
ORDER BY arp.patient_id, e.encounter_date DESC;

-- ============================================================================
-- DEMO QUERY 4: Prescription Adherence Analysis
-- ============================================================================

-- Natural language query for the agent:
-- "What is our overall prescription adherence rate and which medications have the lowest pickup rates?"

-- Overall adherence rate
SELECT 
    COUNT(*) as total_prescriptions,
    COUNT(CASE WHEN pickup_status = 'Picked Up' THEN 1 END) as picked_up_prescriptions,
    COUNT(CASE WHEN pickup_status = 'Not Picked Up' THEN 1 END) as unpicked_prescriptions,
    ROUND(
        (COUNT(CASE WHEN pickup_status = 'Picked Up' THEN 1 END) * 100.0 / COUNT(*)), 
        2
    ) as adherence_rate_percent
FROM AHF_HEALTHCARE_DEMO.MCKESSON_PHARMACY.PRESCRIPTIONS
WHERE prescribed_date >= DATEADD('month', -3, CURRENT_DATE());

-- Medication-specific pickup rates
SELECT 
    medication_name,
    COUNT(*) as total_prescribed,
    COUNT(CASE WHEN pickup_status = 'Picked Up' THEN 1 END) as picked_up,
    COUNT(CASE WHEN pickup_status = 'Not Picked Up' THEN 1 END) as not_picked_up,
    ROUND(
        (COUNT(CASE WHEN pickup_status = 'Picked Up' THEN 1 END) * 100.0 / COUNT(*)), 
        2
    ) as pickup_rate_percent
FROM AHF_HEALTHCARE_DEMO.MCKESSON_PHARMACY.PRESCRIPTIONS
WHERE prescribed_date >= DATEADD('month', -3, CURRENT_DATE())
GROUP BY medication_name
HAVING COUNT(*) >= 2  -- Only show medications with multiple prescriptions
ORDER BY pickup_rate_percent ASC, total_prescribed DESC;

-- ============================================================================
-- ADDITIONAL DEMO QUERIES
-- ============================================================================

-- Provider Performance Metrics
-- Natural language: "Show me provider performance metrics for the last month"
SELECT 
    provider_name,
    COUNT(DISTINCT patient_id) as unique_patients_seen,
    COUNT(*) as total_encounters,
    ROUND(AVG(visit_duration_minutes), 1) as avg_visit_duration,
    SUM(CASE WHEN follow_up_needed = TRUE THEN 1 ELSE 0 END) as followups_scheduled,
    COUNT(DISTINCT encounter_date) as days_active
FROM AHF_HEALTHCARE_DEMO.ATHENA_EHR.ENCOUNTERS
WHERE encounter_date >= DATEADD('month', -1, CURRENT_DATE())
GROUP BY provider_name
ORDER BY total_encounters DESC;

-- Pharmacy Location Utilization
-- Natural language: "Which pharmacy locations are most utilized?"
SELECT 
    pharmacy_location,
    COUNT(*) as total_prescriptions,
    COUNT(CASE WHEN pickup_status = 'Picked Up' THEN 1 END) as picked_up,
    ROUND(
        (COUNT(CASE WHEN pickup_status = 'Picked Up' THEN 1 END) * 100.0 / COUNT(*)), 
        2
    ) as pickup_rate_percent,
    ROUND(AVG(cost), 2) as avg_prescription_cost
FROM AHF_HEALTHCARE_DEMO.MCKESSON_PHARMACY.PRESCRIPTIONS
WHERE prescribed_date >= DATEADD('month', -2, CURRENT_DATE())
GROUP BY pharmacy_location
ORDER BY total_prescriptions DESC;

-- Patient Age Demographics with Encounter Patterns
-- Natural language: "Show me patient demographics and their encounter patterns"
SELECT 
    CASE 
        WHEN DATEDIFF('year', date_of_birth, CURRENT_DATE()) < 18 THEN 'Under 18'
        WHEN DATEDIFF('year', date_of_birth, CURRENT_DATE()) BETWEEN 18 AND 30 THEN '18-30'
        WHEN DATEDIFF('year', date_of_birth, CURRENT_DATE()) BETWEEN 31 AND 50 THEN '31-50'
        WHEN DATEDIFF('year', date_of_birth, CURRENT_DATE()) BETWEEN 51 AND 65 THEN '51-65'
        ELSE 'Over 65'
    END as age_group,
    gender,
    COUNT(DISTINCT p.patient_id) as patient_count,
    COUNT(e.encounter_id) as total_encounters,
    ROUND(COUNT(e.encounter_id) * 1.0 / COUNT(DISTINCT p.patient_id), 2) as avg_encounters_per_patient
FROM AHF_HEALTHCARE_DEMO.ATHENA_EHR.PATIENTS p
LEFT JOIN AHF_HEALTHCARE_DEMO.ATHENA_EHR.ENCOUNTERS e 
    ON p.patient_id = e.patient_id 
    AND e.encounter_date >= DATEADD('month', -3, CURRENT_DATE())
GROUP BY age_group, gender
ORDER BY age_group, gender;

-- ============================================================================
-- AGENT TESTING QUERIES
-- ============================================================================

-- Test the agent with the demo queries
/*
SELECT SNOWFLAKE.CORTEX.COMPLETE_AGENT(
    'AHF_HEALTHCARE_AGENT',
    'Show me our patient encounters per day for the last month'
) AS response_1;

SELECT SNOWFLAKE.CORTEX.COMPLETE_AGENT(
    'AHF_HEALTHCARE_AGENT',
    'Show me patients that haven''t picked up their prescription for the last two months and don''t have an upcoming appointment'
) AS response_2;

SELECT SNOWFLAKE.CORTEX.COMPLETE_AGENT(
    'AHF_HEALTHCARE_AGENT',
    'Summarize the clinical notes for these patients over their last few appointments'
) AS response_3;

SELECT SNOWFLAKE.CORTEX.COMPLETE_AGENT(
    'AHF_HEALTHCARE_AGENT',
    'What is our overall prescription adherence rate and which medications have the lowest pickup rates?'
) AS response_4;
*/
