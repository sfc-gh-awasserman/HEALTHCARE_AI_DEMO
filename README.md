# Snowflake Intelligence Healthcare Demo for Aids Healthcare Foundation

This demo showcases the power of Snowflake Intelligence by integrating data from AthenaHealth EHR and McKesson pharmacy systems to provide comprehensive healthcare insights.

## Demo Overview

This demonstration shows how Snowflake can unify healthcare data from multiple sources to enable:
- Patient encounter analysis
- Prescription fulfillment tracking
- Clinical note summarization
- Cross-system patient insights

## Data Sources

1. **AthenaHealth EHR**: Patient encounters, appointments, clinical notes
2. **McKesson Pharmacy**: Prescription data, fulfillment status, medication details

## Demo Flow

The demo follows this narrative:
1. Show patient encounters per day for the last month
2. Identify patients who haven't picked up prescriptions and have no upcoming appointments
3. Summarize clinical notes for these at-risk patients

## Project Structure

```
├── data/                    # Sample datasets
├── sql/                     # Database setup scripts
├── semantic_models/         # Snowflake Intelligence semantic models
├── agents/                  # Agent configurations
├── demo/                    # Demo scripts and talk tracks
└── docs/                    # Documentation
```

## Quick Start

1. Set up Snowflake environment
2. Load sample data using scripts in `sql/`
3. Create semantic models from `semantic_models/`
4. Configure agents from `agents/`
5. Run demo using scripts in `demo/`

## Requirements

- Snowflake account with Intelligence features enabled
- Appropriate permissions for creating semantic views and agents
- Sample data or connections to actual AthenaHealth/McKesson systems
