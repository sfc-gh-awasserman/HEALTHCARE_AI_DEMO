# Healthcare Demo Checklist

## Pre-Demo Setup (30 minutes before demo)

### Environment Verification
- [ ] Snowflake account is accessible and responsive
- [ ] Database `AHF_HEALTHCARE_DEMO` exists and is populated
- [ ] All schemas (ATHENA_EHR, MCKESSON_PHARMACY, ANALYTICS) are created
- [ ] Sample data is loaded in all tables
- [ ] Semantic view `AHF_HEALTHCARE_ANALYTICS_SEMANTIC_VIEW` is created
- [ ] Agent `AHF_HEALTHCARE_AGENT` is configured and responsive

### Data Validation
- [ ] Patients table has 15 records
- [ ] Encounters table has 20+ records
- [ ] Appointments table has 15+ records  
- [ ] Prescriptions table has 23+ records
- [ ] Pharmacy locations table has 14+ records

### Test Queries
- [ ] Run sample query 1: "Show me our patient encounters per day for the last month"
- [ ] Run sample query 2: "Show me patients that haven't picked up their prescription for the last two months and don't have an upcoming appointment"
- [ ] Verify agent responses are reasonable and formatted well
- [ ] Check that clinical notes are being properly summarized

## Demo Materials Ready

### Presentation Materials
- [ ] Demo talk track printed/accessible
- [ ] Sample queries ready in SQL worksheet
- [ ] Backup slides prepared (in case of technical issues)
- [ ] Business value talking points memorized

### Technical Setup
- [ ] Screen sharing tested and working
- [ ] Snowflake interface clean and organized
- [ ] Worksheets organized with clear names
- [ ] Font size appropriate for audience viewing
- [ ] Network connection stable

## During Demo Execution

### Opening (2 minutes)
- [ ] Introduce the scenario and value proposition
- [ ] Explain data sources (AthenaHealth + McKesson)
- [ ] Set expectations for what we'll demonstrate

### Query 1: Operational Overview (3 minutes)
- [ ] Execute: "Show me our patient encounters per day for the last month"
- [ ] Highlight key insights from results
- [ ] Explain business value (staffing, capacity planning)
- [ ] Show how easy natural language querying is

### Query 2: At-Risk Patient Identification (5 minutes)
- [ ] Execute: "Show me patients that haven't picked up their prescription for the last two months and don't have an upcoming appointment"
- [ ] Point out specific patient examples
- [ ] Highlight actionable information (contact details, medications)
- [ ] Emphasize proactive care management value

### Query 3: Clinical Context (4 minutes)
- [ ] Execute: "Summarize the clinical notes for these patients over their last few appointments"
- [ ] Show how AI summarizes complex clinical information
- [ ] Demonstrate care continuity insights
- [ ] Highlight prioritization capabilities

### Query 4: Prescription Analytics (3 minutes)
- [ ] Execute: "What is our overall prescription adherence rate and which medications have the lowest pickup rates?"
- [ ] Show adherence metrics and trends
- [ ] Identify improvement opportunities
- [ ] Connect to quality outcomes

### Closing (2 minutes)
- [ ] Summarize key capabilities demonstrated
- [ ] Reinforce business value and ROI
- [ ] Transition to Q&A and next steps

## Post-Demo Follow-up

### Immediate Actions
- [ ] Capture any specific questions or requirements mentioned
- [ ] Schedule follow-up meeting if requested
- [ ] Send demo summary and next steps via email
- [ ] Provide access to demo environment if appropriate

### Documentation
- [ ] Note any technical issues encountered
- [ ] Record audience feedback and reactions
- [ ] Update demo materials based on lessons learned
- [ ] Document any customization requests

## Troubleshooting Guide

### Common Issues and Solutions

**Agent not responding:**
- Check agent status and permissions
- Verify semantic view is accessible
- Fall back to direct SQL queries if needed

**Data not showing expected results:**
- Verify date ranges in sample data
- Check data loading completion
- Use backup queries with known results

**Performance issues:**
- Ensure warehouse is running and sized appropriately
- Pre-warm queries if possible
- Have simplified queries ready as backup

**Network/connectivity problems:**
- Have offline slides ready
- Use mobile hotspot as backup
- Consider rescheduling if critical systems are down

### Backup Plans

**Technical Failure:**
- Switch to presentation slides with screenshots
- Walk through the concept using static examples
- Schedule technical deep-dive for later

**Data Issues:**
- Use pre-captured screenshots of results
- Explain what the queries would show
- Focus on business value discussion

**Time Constraints:**
- Prioritize Query 2 (at-risk patients) as highest value
- Combine queries 3 and 4 if needed
- Extend Q&A to cover missed content

## Success Metrics

### Engagement Indicators
- [ ] Audience asking clarifying questions
- [ ] Requests for specific use cases
- [ ] Discussion of implementation timeline
- [ ] Interest in pilot program

### Technical Validation
- [ ] All queries executed successfully
- [ ] Results were meaningful and accurate
- [ ] Agent responses were appropriate
- [ ] No significant technical issues

### Business Impact
- [ ] Clear understanding of value proposition
- [ ] Specific use cases identified for AHF
- [ ] Next steps agreed upon
- [ ] Stakeholder buy-in achieved
