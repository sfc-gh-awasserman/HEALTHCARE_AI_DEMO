# Snowflake Intelligence Healthcare Demo Setup Guide

## Prerequisites

### Snowflake Account Requirements
- Snowflake account with Intelligence features enabled
- Cortex AI services available in your region
- Appropriate compute warehouse (SMALL or larger recommended)
- Permissions to create databases, schemas, tables, and semantic views

### Required Roles and Permissions
```sql
-- Minimum required permissions
GRANT CREATE DATABASE ON ACCOUNT TO ROLE <your_role>;
GRANT CREATE SCHEMA ON DATABASE <database_name> TO ROLE <your_role>;
GRANT CREATE TABLE ON SCHEMA <schema_name> TO ROLE <your_role>;
GRANT CREATE VIEW ON SCHEMA <schema_name> TO ROLE <your_role>;
GRANT CREATE SEMANTIC VIEW ON SCHEMA <schema_name> TO ROLE <your_role>;
GRANT CREATE AGENT ON SCHEMA <schema_name> TO ROLE <your_role>;
GRANT USAGE ON WAREHOUSE <warehouse_name> TO ROLE <your_role>;
```

### Software Requirements
- Snowflake web interface or SnowSQL CLI
- Access to upload CSV files (for sample data)
- Text editor for SQL scripts

## Installation Steps

### Step 1: Database and Schema Setup (5 minutes)

1. **Execute Database Setup Script**
   ```bash
   # Using SnowSQL
   snowsql -f sql/01_setup_database.sql
   
   # Or copy/paste into Snowflake web interface
   ```

2. **Verify Database Creation**
   ```sql
   SHOW DATABASES LIKE 'AHF_HEALTHCARE_DEMO';
   SHOW SCHEMAS IN DATABASE AHF_HEALTHCARE_DEMO;
   ```

### Step 2: Create Tables (10 minutes)

1. **Create AthenaHealth EHR Tables**
   ```bash
   snowsql -f sql/02_create_athena_tables.sql
   ```

2. **Create McKesson Pharmacy Tables**
   ```bash
   snowsql -f sql/03_create_mckesson_tables.sql
   ```

3. **Verify Table Creation**
   ```sql
   USE DATABASE AHF_HEALTHCARE_DEMO;
   SHOW TABLES IN SCHEMA ATHENA_EHR;
   SHOW TABLES IN SCHEMA MCKESSON_PHARMACY;
   ```

### Step 3: Load Sample Data (15 minutes)

1. **Upload CSV Files to Snowflake Stage**
   ```sql
   USE DATABASE AHF_HEALTHCARE_DEMO;
   
   -- Upload files using PUT command (adjust paths as needed)
   PUT file://data/athena_patients.csv @HEALTHCARE_DATA_STAGE;
   PUT file://data/athena_encounters.csv @HEALTHCARE_DATA_STAGE;
   PUT file://data/athena_appointments.csv @HEALTHCARE_DATA_STAGE;
   PUT file://data/mckesson_prescriptions.csv @HEALTHCARE_DATA_STAGE;
   PUT file://data/mckesson_pharmacy_locations.csv @HEALTHCARE_DATA_STAGE;
   ```

2. **Load Data into Tables**
   ```sql
   -- Load AthenaHealth data
   USE SCHEMA ATHENA_EHR;
   
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
   
   -- Load McKesson data
   USE SCHEMA MCKESSON_PHARMACY;
   
   COPY INTO PHARMACY_LOCATIONS
   FROM @HEALTHCARE_DATA_STAGE/mckesson_pharmacy_locations.csv
   FILE_FORMAT = CSV_FORMAT
   ON_ERROR = 'CONTINUE';
   
   COPY INTO PRESCRIPTIONS
   FROM @HEALTHCARE_DATA_STAGE/mckesson_prescriptions.csv
   FILE_FORMAT = CSV_FORMAT
   ON_ERROR = 'CONTINUE';
   ```

3. **Verify Data Loading**
   ```sql
   -- Check record counts
   SELECT 'PATIENTS' AS TABLE_NAME, COUNT(*) AS RECORD_COUNT FROM ATHENA_EHR.PATIENTS
   UNION ALL
   SELECT 'ENCOUNTERS' AS TABLE_NAME, COUNT(*) AS RECORD_COUNT FROM ATHENA_EHR.ENCOUNTERS
   UNION ALL
   SELECT 'APPOINTMENTS' AS TABLE_NAME, COUNT(*) AS RECORD_COUNT FROM ATHENA_EHR.APPOINTMENTS
   UNION ALL
   SELECT 'PRESCRIPTIONS' AS TABLE_NAME, COUNT(*) AS RECORD_COUNT FROM MCKESSON_PHARMACY.PRESCRIPTIONS
   UNION ALL
   SELECT 'PHARMACY_LOCATIONS' AS TABLE_NAME, COUNT(*) AS RECORD_COUNT FROM MCKESSON_PHARMACY.PHARMACY_LOCATIONS;
   ```

### Step 4: Create Analytics Views (5 minutes)

1. **Execute Analytics Views Script**
   ```bash
   snowsql -f sql/05_create_analytics_views.sql
   ```

2. **Verify Views Creation**
   ```sql
   USE SCHEMA ANALYTICS;
   SHOW VIEWS;
   
   -- Test a view
   SELECT * FROM PATIENT_UNIFIED LIMIT 5;
   ```

### Step 5: Create Semantic Model (10 minutes)

1. **Upload YAML Configuration**
   ```sql
   -- Upload the semantic model YAML file
   PUT file://semantic_models/healthcare_semantic_model.yaml @HEALTHCARE_DATA_STAGE;
   ```

2. **Create Semantic View**
   ```bash
   snowsql -f sql/06_create_semantic_view.sql
   ```

3. **Verify Semantic View**
   ```sql
   USE SCHEMA ANALYTICS;
   DESCRIBE SEMANTIC VIEW AHF_HEALTHCARE_ANALYTICS_SEMANTIC_VIEW;
   ```

### Step 6: Configure Intelligence Agent (10 minutes)

1. **Create the Agent**
   ```bash
   snowsql -f agents/healthcare_agent_config.sql
   ```

2. **Test Agent Functionality**
   ```sql
   -- Test basic agent response
   SELECT SNOWFLAKE.CORTEX.COMPLETE_AGENT(
       'AHF_HEALTHCARE_AGENT',
       'How many patients do we have in the system?'
   ) AS test_response;
   ```

## Configuration Options

### Warehouse Sizing
- **XSMALL**: Suitable for initial testing (1-5 users)
- **SMALL**: Recommended for demo environment (5-10 users) - **Created by default**
- **MEDIUM**: Production environment (10+ users)

Note: The setup script creates `AHF_DEMO_WH` warehouse automatically.

### Security Configuration
```sql
-- Create role-based access
CREATE ROLE IF NOT EXISTS HEALTHCARE_ANALYST;
CREATE ROLE IF NOT EXISTS HEALTHCARE_ADMIN;

-- Grant permissions
GRANT USAGE ON DATABASE AHF_HEALTHCARE_DEMO TO ROLE HEALTHCARE_ANALYST;
GRANT USAGE ON ALL SCHEMAS IN DATABASE AHF_HEALTHCARE_DEMO TO ROLE HEALTHCARE_ANALYST;
GRANT SELECT ON ALL TABLES IN DATABASE AHF_HEALTHCARE_DEMO TO ROLE HEALTHCARE_ANALYST;
GRANT SELECT ON ALL VIEWS IN DATABASE AHF_HEALTHCARE_DEMO TO ROLE HEALTHCARE_ANALYST;
GRANT USAGE ON AGENT AHF_HEALTHCARE_AGENT TO ROLE HEALTHCARE_ANALYST;
```

### Performance Optimization
```sql
-- Create clustering keys for large tables (if needed)
ALTER TABLE ATHENA_EHR.ENCOUNTERS CLUSTER BY (ENCOUNTER_DATE, PATIENT_ID);
ALTER TABLE MCKESSON_PHARMACY.PRESCRIPTIONS CLUSTER BY (PRESCRIBED_DATE, PATIENT_ID);

-- Create search optimization (if available)
ALTER TABLE ATHENA_EHR.PATIENTS ADD SEARCH OPTIMIZATION;
ALTER TABLE ATHENA_EHR.ENCOUNTERS ADD SEARCH OPTIMIZATION;
```

## Troubleshooting

### Common Issues

**Issue: "Database does not exist" error**
```sql
-- Solution: Verify database creation
SHOW DATABASES LIKE 'AHF_HEALTHCARE_DEMO';
-- If not found, re-run step 1
```

**Issue: "File not found" during data loading**
```sql
-- Solution: Check stage contents
LIST @HEALTHCARE_DATA_STAGE;
-- Re-upload files if missing
```

**Issue: "Insufficient privileges" error**
```sql
-- Solution: Check role permissions
SHOW GRANTS TO ROLE <your_role>;
-- Contact admin to grant required permissions
```

**Issue: Agent not responding**
```sql
-- Solution: Verify agent exists and permissions
SHOW AGENTS;
DESCRIBE AGENT AHF_HEALTHCARE_AGENT;
-- Check semantic view accessibility
```

### Performance Issues

**Slow Query Performance:**
1. Check warehouse size and scaling policy
2. Verify clustering keys are in place
3. Consider result caching settings
4. Review query patterns for optimization

**Agent Response Delays:**
1. Ensure Cortex services are available in your region
2. Check warehouse auto-suspend settings
3. Verify semantic view complexity
4. Consider pre-warming with sample queries

## Validation Checklist

### Data Validation
- [ ] All tables contain expected number of records
- [ ] Date ranges in sample data are appropriate
- [ ] Foreign key relationships are intact
- [ ] No duplicate primary keys

### Functionality Validation
- [ ] All views return data without errors
- [ ] Semantic view describes successfully
- [ ] Agent responds to basic queries
- [ ] Sample demo queries execute successfully

### Performance Validation
- [ ] Queries complete within acceptable time (< 30 seconds)
- [ ] Agent responses are generated within 1-2 minutes
- [ ] Warehouse auto-suspends properly
- [ ] No resource contention issues

## Maintenance

### Regular Tasks
- **Weekly**: Review query performance and optimize as needed
- **Monthly**: Update sample data to keep demo current
- **Quarterly**: Review and update semantic model based on feedback

### Monitoring
```sql
-- Monitor warehouse usage
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE WAREHOUSE_NAME = 'COMPUTE_WH'
AND START_TIME >= DATEADD('day', -7, CURRENT_TIMESTAMP());

-- Monitor query performance
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE DATABASE_NAME = 'AHF_HEALTHCARE_DEMO'
AND START_TIME >= DATEADD('day', -1, CURRENT_TIMESTAMP())
ORDER BY TOTAL_ELAPSED_TIME DESC;
```

## Support and Resources

### Documentation Links
- [Snowflake Intelligence Documentation](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-intelligence)
- [Semantic Views Guide](https://docs.snowflake.com/en/user-guide/views-semantic)
- [Agent Configuration](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-intelligence/agents)

### Getting Help
- Snowflake Support Portal
- Community Forums
- Professional Services team
- Technical Account Manager

### Demo Environment Access
- Environment URL: [Your Snowflake Account URL]
- Demo Database: `AHF_HEALTHCARE_DEMO`
- Sample Credentials: [Provide as appropriate]
