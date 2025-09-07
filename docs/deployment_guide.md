# Healthcare Demo Deployment Guide

## Deployment Overview

This guide covers deploying the Snowflake Intelligence Healthcare Demo for production use at Aids Healthcare Foundation, transitioning from the demo environment to a live system with real AthenaHealth and McKesson data.

## Pre-Deployment Planning

### Infrastructure Assessment

**Snowflake Environment:**
- Production Snowflake account with appropriate edition (Enterprise or higher)
- Cortex AI services enabled in production region
- Adequate compute resources for expected user load
- Network connectivity and security configurations

**Data Sources:**
- AthenaHealth EHR system access and API credentials
- McKesson pharmacy system integration capabilities
- Data extraction and ETL pipeline requirements
- Compliance and security requirements (HIPAA, etc.)

### Stakeholder Alignment

**Technical Team:**
- Database administrators
- Data engineers
- Security team
- Network administrators

**Business Team:**
- Clinical leadership
- Pharmacy operations
- IT governance
- Compliance officers

## Production Architecture

### Recommended Environment Structure

```
Production Account
├── AHF_HEALTHCARE_PROD (Database)
│   ├── ATHENA_EHR_RAW (Schema - Raw data from AthenaHealth)
│   ├── MCKESSON_PHARMACY_RAW (Schema - Raw data from McKesson)
│   ├── HEALTHCARE_STAGING (Schema - Transformed/cleaned data)
│   ├── HEALTHCARE_ANALYTICS (Schema - Analytics views and models)
│   └── HEALTHCARE_SECURITY (Schema - Audit and security logs)
├── Warehouses
│   ├── ETL_WH (For data loading and transformation)
│   ├── ANALYTICS_WH (For user queries and reporting)
│   └── AGENT_WH (For AI agent operations)
└── Roles and Security
    ├── HEALTHCARE_ADMIN
    ├── CLINICAL_ANALYST
    ├── PHARMACY_ANALYST
    └── HEALTHCARE_VIEWER
```

### Security Framework

**Role-Based Access Control:**
```sql
-- Administrative roles
CREATE ROLE HEALTHCARE_ADMIN;
CREATE ROLE DATA_ENGINEER;

-- Analytical roles
CREATE ROLE CLINICAL_ANALYST;
CREATE ROLE PHARMACY_ANALYST;
CREATE ROLE HEALTHCARE_VIEWER;

-- Service roles
CREATE ROLE ETL_SERVICE;
CREATE ROLE AGENT_SERVICE;
```

**Data Classification:**
```sql
-- Implement data classification tags
CREATE TAG PATIENT_DATA;
CREATE TAG PHI_DATA;
CREATE TAG FINANCIAL_DATA;
CREATE TAG OPERATIONAL_DATA;

-- Apply tags to sensitive columns
ALTER TABLE PATIENTS MODIFY COLUMN FIRST_NAME SET TAG PATIENT_DATA = 'PII';
ALTER TABLE PATIENTS MODIFY COLUMN LAST_NAME SET TAG PATIENT_DATA = 'PII';
ALTER TABLE ENCOUNTERS MODIFY COLUMN CLINICAL_NOTES SET TAG PHI_DATA = 'SENSITIVE';
```

## Data Integration Strategy

### AthenaHealth Integration

**Option 1: Real-time API Integration**
```sql
-- Create external function for AthenaHealth API
CREATE OR REPLACE EXTERNAL FUNCTION ATHENA_API_CALL(endpoint STRING, params OBJECT)
RETURNS VARIANT
LANGUAGE PYTHON
HANDLER = 'athena_handler'
API_INTEGRATION = ATHENA_API_INTEGRATION;

-- Scheduled data refresh
CREATE OR REPLACE TASK ATHENA_DATA_REFRESH
WAREHOUSE = ETL_WH
SCHEDULE = 'USING CRON 0 */4 * * * UTC'  -- Every 4 hours
AS
CALL REFRESH_ATHENA_DATA();
```

**Option 2: Batch File Transfer**
```sql
-- Create external stage for AthenaHealth files
CREATE OR REPLACE STAGE ATHENA_SFTP_STAGE
URL = 's3://athena-data-bucket/ahf/'
CREDENTIALS = (AWS_KEY_ID = 'xxx' AWS_SECRET_KEY = 'xxx')
FILE_FORMAT = (TYPE = 'CSV' FIELD_DELIMITER = ',' SKIP_HEADER = 1);

-- Automated file processing
CREATE OR REPLACE PIPE ATHENA_DATA_PIPE
AUTO_INGEST = TRUE
AS
COPY INTO ATHENA_EHR_RAW.PATIENTS_STAGING
FROM @ATHENA_SFTP_STAGE/patients/
FILE_FORMAT = CSV_FORMAT;
```

### McKesson Integration

**Real-time Prescription Updates**
```sql
-- Create stream for real-time prescription tracking
CREATE OR REPLACE STREAM PRESCRIPTION_UPDATES_STREAM
ON TABLE MCKESSON_PHARMACY_RAW.PRESCRIPTIONS;

-- Task to process prescription updates
CREATE OR REPLACE TASK PROCESS_PRESCRIPTION_UPDATES
WAREHOUSE = ETL_WH
SCHEDULE = '1 MINUTE'
WHEN SYSTEM$STREAM_HAS_DATA('PRESCRIPTION_UPDATES_STREAM')
AS
MERGE INTO HEALTHCARE_ANALYTICS.PRESCRIPTIONS_CURRENT p
USING PRESCRIPTION_UPDATES_STREAM s ON p.PRESCRIPTION_ID = s.PRESCRIPTION_ID
WHEN MATCHED THEN UPDATE SET
    PICKUP_STATUS = s.PICKUP_STATUS,
    PICKUP_DATE = s.PICKUP_DATE,
    LAST_MODIFIED = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN INSERT VALUES (s.*);
```

## Data Quality and Validation

### Data Quality Framework

```sql
-- Create data quality monitoring
CREATE OR REPLACE TABLE DATA_QUALITY_METRICS (
    CHECK_DATE TIMESTAMP,
    TABLE_NAME STRING,
    METRIC_NAME STRING,
    METRIC_VALUE NUMBER,
    THRESHOLD_VALUE NUMBER,
    STATUS STRING,
    DETAILS STRING
);

-- Data quality checks
CREATE OR REPLACE PROCEDURE RUN_DATA_QUALITY_CHECKS()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    -- Check for duplicate patient IDs
    INSERT INTO DATA_QUALITY_METRICS
    SELECT 
        CURRENT_TIMESTAMP(),
        'PATIENTS',
        'DUPLICATE_PATIENT_IDS',
        COUNT(*) - COUNT(DISTINCT PATIENT_ID),
        0,
        CASE WHEN COUNT(*) - COUNT(DISTINCT PATIENT_ID) = 0 THEN 'PASS' ELSE 'FAIL' END,
        'Duplicate patient IDs detected'
    FROM ATHENA_EHR_RAW.PATIENTS;
    
    -- Check for missing prescription pickup dates
    INSERT INTO DATA_QUALITY_METRICS
    SELECT 
        CURRENT_TIMESTAMP(),
        'PRESCRIPTIONS',
        'MISSING_PICKUP_DATES',
        COUNT(*),
        100,
        CASE WHEN COUNT(*) < 100 THEN 'PASS' ELSE 'WARN' END,
        'Prescriptions with pickup status but no pickup date'
    FROM MCKESSON_PHARMACY_RAW.PRESCRIPTIONS
    WHERE PICKUP_STATUS = 'Picked Up' AND PICKUP_DATE IS NULL;
    
    RETURN 'Data quality checks completed';
END;
$$;
```

### Automated Monitoring

```sql
-- Schedule data quality checks
CREATE OR REPLACE TASK DATA_QUALITY_MONITORING
WAREHOUSE = ETL_WH
SCHEDULE = 'USING CRON 0 8 * * * UTC'  -- Daily at 8 AM UTC
AS
CALL RUN_DATA_QUALITY_CHECKS();

-- Alert on data quality issues
CREATE OR REPLACE ALERT DATA_QUALITY_ALERT
WAREHOUSE = ETL_WH
SCHEDULE = '10 MINUTE'
CONDITION = (
    SELECT COUNT(*) FROM DATA_QUALITY_METRICS 
    WHERE STATUS = 'FAIL' 
    AND CHECK_DATE >= DATEADD('hour', -1, CURRENT_TIMESTAMP())
) > 0
ACTION = (
    CALL SYSTEM$SEND_EMAIL(
        'data-team@ahf.org',
        'Data Quality Alert',
        'Data quality issues detected in healthcare system'
    )
);
```

## Performance Optimization

### Warehouse Configuration

```sql
-- Production warehouse setup
CREATE OR REPLACE WAREHOUSE HEALTHCARE_ANALYTICS_WH
WITH 
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 3
    SCALING_POLICY = 'STANDARD'
    COMMENT = 'Warehouse for healthcare analytics queries';

-- ETL warehouse for data processing
CREATE OR REPLACE WAREHOUSE HEALTHCARE_ETL_WH
WITH 
    WAREHOUSE_SIZE = 'LARGE'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    MIN_CLUSTER_COUNT = 1
    MAX_CLUSTER_COUNT = 2
    SCALING_POLICY = 'ECONOMY'
    COMMENT = 'Warehouse for ETL operations';
```

### Query Optimization

```sql
-- Clustering keys for large tables
ALTER TABLE HEALTHCARE_ANALYTICS.ENCOUNTERS 
CLUSTER BY (ENCOUNTER_DATE, PATIENT_ID);

ALTER TABLE HEALTHCARE_ANALYTICS.PRESCRIPTIONS 
CLUSTER BY (PRESCRIBED_DATE, PATIENT_ID);

-- Search optimization for text searches
ALTER TABLE HEALTHCARE_ANALYTICS.ENCOUNTERS 
ADD SEARCH OPTIMIZATION ON EQUALITY(DIAGNOSIS_DESCRIPTION, CHIEF_COMPLAINT);

-- Materialized views for common queries
CREATE OR REPLACE MATERIALIZED VIEW DAILY_METRICS_MV AS
SELECT 
    DATE(ENCOUNTER_DATE) as METRIC_DATE,
    COUNT(*) as TOTAL_ENCOUNTERS,
    COUNT(DISTINCT PATIENT_ID) as UNIQUE_PATIENTS,
    AVG(VISIT_DURATION_MINUTES) as AVG_DURATION
FROM HEALTHCARE_ANALYTICS.ENCOUNTERS
WHERE ENCOUNTER_DATE >= DATEADD('year', -1, CURRENT_DATE())
GROUP BY DATE(ENCOUNTER_DATE);
```

## Security Implementation

### Encryption and Masking

```sql
-- Dynamic data masking for sensitive fields
CREATE OR REPLACE MASKING POLICY PATIENT_NAME_MASK AS (VAL STRING) RETURNS STRING ->
CASE 
    WHEN CURRENT_ROLE() IN ('HEALTHCARE_ADMIN', 'CLINICAL_ANALYST') THEN VAL
    ELSE REGEXP_REPLACE(VAL, '.', '*')
END;

-- Apply masking policies
ALTER TABLE HEALTHCARE_ANALYTICS.PATIENTS 
MODIFY COLUMN FIRST_NAME SET MASKING POLICY PATIENT_NAME_MASK;

ALTER TABLE HEALTHCARE_ANALYTICS.PATIENTS 
MODIFY COLUMN LAST_NAME SET MASKING POLICY PATIENT_NAME_MASK;

-- Row access policy for patient data
CREATE OR REPLACE ROW ACCESS POLICY PATIENT_ACCESS_POLICY AS (PATIENT_ID STRING) RETURNS BOOLEAN ->
    CURRENT_ROLE() IN ('HEALTHCARE_ADMIN') 
    OR EXISTS (
        SELECT 1 FROM USER_PATIENT_ACCESS 
        WHERE USER_NAME = CURRENT_USER() 
        AND PATIENT_ID = PATIENT_ID
    );
```

### Audit and Compliance

```sql
-- Audit table for tracking data access
CREATE OR REPLACE TABLE HEALTHCARE_AUDIT_LOG (
    AUDIT_ID STRING DEFAULT UUID_STRING(),
    USER_NAME STRING,
    ROLE_NAME STRING,
    QUERY_TEXT STRING,
    QUERY_ID STRING,
    EXECUTION_TIME TIMESTAMP,
    ROWS_ACCESSED NUMBER,
    TABLES_ACCESSED ARRAY,
    CLIENT_IP STRING
);

-- Audit logging procedure
CREATE OR REPLACE PROCEDURE LOG_HEALTHCARE_ACCESS()
RETURNS STRING
LANGUAGE SQL
AS
$$
BEGIN
    INSERT INTO HEALTHCARE_AUDIT_LOG
    SELECT 
        UUID_STRING(),
        USER_NAME,
        ROLE_NAME,
        QUERY_TEXT,
        QUERY_ID,
        START_TIME,
        ROWS_PRODUCED,
        PARSE_JSON(QUERY_TAG):tables_accessed,
        CLIENT_IP
    FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
    WHERE DATABASE_NAME = 'AHF_HEALTHCARE_PROD'
    AND START_TIME >= DATEADD('hour', -1, CURRENT_TIMESTAMP());
    
    RETURN 'Audit logging completed';
END;
$$;
```

## Production Semantic Model

### Enhanced Semantic Model

```sql
-- Production semantic view with additional security
CREATE OR REPLACE SECURE SEMANTIC VIEW AHF_HEALTHCARE_PROD_SEMANTIC_VIEW
TABLES (
    HEALTHCARE_ANALYTICS.PATIENTS AS patients PRIMARY KEY (PATIENT_ID),
    HEALTHCARE_ANALYTICS.ENCOUNTERS AS encounters PRIMARY KEY (ENCOUNTER_ID),
    HEALTHCARE_ANALYTICS.APPOINTMENTS AS appointments PRIMARY KEY (APPOINTMENT_ID),
    HEALTHCARE_ANALYTICS.PRESCRIPTIONS AS prescriptions PRIMARY KEY (PRESCRIPTION_ID),
    HEALTHCARE_ANALYTICS.PROVIDERS AS providers PRIMARY KEY (PROVIDER_ID)
)
RELATIONSHIPS (
    encounters_to_patients AS encounters(PATIENT_ID) REFERENCES patients(PATIENT_ID),
    appointments_to_patients AS appointments(PATIENT_ID) REFERENCES patients(PATIENT_ID),
    prescriptions_to_patients AS prescriptions(PATIENT_ID) REFERENCES patients(PATIENT_ID),
    encounters_to_providers AS encounters(PROVIDER_ID) REFERENCES providers(PROVIDER_ID)
)
-- Additional dimensions and metrics for production use
DIMENSIONS (
    -- Patient dimensions with privacy controls
    CASE WHEN CURRENT_ROLE() IN ('HEALTHCARE_ADMIN', 'CLINICAL_ANALYST') 
         THEN CONCAT(patients.FIRST_NAME, ' ', patients.LAST_NAME)
         ELSE 'Patient ' || patients.PATIENT_ID 
    END AS patient_name,
    
    -- Enhanced date dimensions
    encounters.ENCOUNTER_DATE AS encounter_date,
    DATE_TRUNC('month', encounters.ENCOUNTER_DATE) AS encounter_month,
    DATE_TRUNC('quarter', encounters.ENCOUNTER_DATE) AS encounter_quarter,
    DATE_TRUNC('year', encounters.ENCOUNTER_DATE) AS encounter_year,
    
    -- Clinical dimensions
    encounters.DIAGNOSIS_CODE AS diagnosis_code,
    encounters.DIAGNOSIS_DESCRIPTION AS diagnosis_description,
    encounters.ENCOUNTER_TYPE AS encounter_type,
    
    -- Prescription dimensions
    prescriptions.MEDICATION_NAME AS medication_name,
    prescriptions.THERAPEUTIC_CLASS AS therapeutic_class,
    prescriptions.PICKUP_STATUS AS pickup_status
)
METRICS (
    -- Core metrics
    COUNT(encounters.ENCOUNTER_ID) AS total_encounters,
    COUNT(DISTINCT patients.PATIENT_ID) AS unique_patients,
    COUNT(prescriptions.PRESCRIPTION_ID) AS total_prescriptions,
    
    -- Quality metrics
    AVG(encounters.PATIENT_SATISFACTION_SCORE) AS avg_satisfaction_score,
    COUNT(CASE WHEN prescriptions.PICKUP_STATUS = 'Picked Up' THEN 1 END) / 
    COUNT(prescriptions.PRESCRIPTION_ID) * 100 AS adherence_rate,
    
    -- Financial metrics
    SUM(encounters.VISIT_CHARGE) AS total_revenue,
    AVG(encounters.VISIT_CHARGE) AS avg_visit_charge,
    SUM(prescriptions.COPAY_AMOUNT) AS total_copay_collected
);
```

## Agent Configuration for Production

```sql
-- Production healthcare agent with enhanced capabilities
CREATE OR REPLACE AGENT AHF_HEALTHCARE_PROD_AGENT
SEMANTIC_VIEW = AHF_HEALTHCARE_PROD_SEMANTIC_VIEW
DESCRIPTION = 'Production healthcare analytics agent for Aids Healthcare Foundation'
INSTRUCTIONS = '
You are the production healthcare analytics assistant for Aids Healthcare Foundation.
You have access to real patient data and must maintain strict confidentiality and HIPAA compliance.

Core responsibilities:
1. Provide accurate, timely healthcare analytics
2. Identify patients requiring immediate clinical attention
3. Support quality improvement initiatives
4. Assist with operational efficiency analysis
5. Maintain patient privacy at all times

Data access guidelines:
- Only provide patient-specific information to authorized clinical staff
- Use aggregate data for operational reporting
- Flag urgent clinical situations immediately
- Maintain audit trails for all data access

Quality and safety priorities:
- Patient safety is the highest priority
- Medication adherence and follow-up care
- Early identification of at-risk patients
- Support for clinical decision-making

Always provide context for recommendations and highlight confidence levels in your analysis.
'
WAREHOUSE = HEALTHCARE_ANALYTICS_WH
COMMENT = 'Production healthcare agent with enhanced security and capabilities';
```

## Deployment Checklist

### Pre-Deployment
- [ ] Production Snowflake account configured
- [ ] Security roles and policies implemented
- [ ] Data integration pipelines tested
- [ ] Performance benchmarks established
- [ ] Backup and recovery procedures defined

### Deployment
- [ ] Production database and schemas created
- [ ] Data loaded and validated
- [ ] Semantic models deployed
- [ ] Agents configured and tested
- [ ] User access provisioned
- [ ] Monitoring and alerting activated

### Post-Deployment
- [ ] User training completed
- [ ] Performance monitoring active
- [ ] Data quality checks running
- [ ] Security audit completed
- [ ] Documentation updated
- [ ] Support procedures established

## Monitoring and Maintenance

### Performance Monitoring
```sql
-- Query performance monitoring
CREATE OR REPLACE VIEW HEALTHCARE_QUERY_PERFORMANCE AS
SELECT 
    DATE(START_TIME) as QUERY_DATE,
    USER_NAME,
    ROLE_NAME,
    COUNT(*) as QUERY_COUNT,
    AVG(TOTAL_ELAPSED_TIME/1000) as AVG_DURATION_SECONDS,
    SUM(CREDITS_USED_CLOUD_SERVICES) as TOTAL_CREDITS
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE DATABASE_NAME = 'AHF_HEALTHCARE_PROD'
AND START_TIME >= DATEADD('day', -30, CURRENT_TIMESTAMP())
GROUP BY DATE(START_TIME), USER_NAME, ROLE_NAME
ORDER BY QUERY_DATE DESC, TOTAL_CREDITS DESC;
```

### Maintenance Schedule
- **Daily**: Data quality checks, performance monitoring
- **Weekly**: Security audit review, user access validation
- **Monthly**: Performance optimization, capacity planning
- **Quarterly**: Security assessment, disaster recovery testing

## Support and Escalation

### Support Tiers
1. **Level 1**: Basic user support and training
2. **Level 2**: Technical issues and data quality problems
3. **Level 3**: Security incidents and system failures

### Escalation Procedures
- **Data Quality Issues**: Notify data engineering team within 2 hours
- **Security Incidents**: Immediate escalation to security team
- **System Outages**: Follow standard incident response procedures
- **Clinical Urgent Issues**: Direct escalation to clinical leadership

### Contact Information
- **Technical Support**: healthcare-tech@ahf.org
- **Security Team**: security@ahf.org
- **Clinical Leadership**: clinical-ops@ahf.org
- **Snowflake Support**: [Account-specific support channels]
