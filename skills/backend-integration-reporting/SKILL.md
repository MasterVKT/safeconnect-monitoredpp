---
name: backend-integration-reporting
description: 'Detect, classify, and document backend or integration-side issues for Monitored App. Use when API/WS/auth contract failures occur (4xx/5xx, schema mismatch, auth errors, null critical fields, disconnections). Produces actionable docs/integration_issues reports following the mandatory template, proposes precise backend fixes, and includes conditional frontend-remediation details when applicable.'
argument-hint: 'Provide failing endpoint/feature, request/response evidence, and reproduction context.'
user-invocable: true
---

# Backend Integration Reporting (Monitored App)

## Purpose
Create high-quality, actionable integration issue reports when problems are backend-side or contract-side.

## Use When
- HTTP 4xx/5xx from backend
- Response schema mismatch
- Authentication/authorization failure (401/403)
- WebSocket connection instability or command payload mismatch
- Unexpected null in required fields

## Mandatory Output File
Create:
docs/integration_issues/INTEGRATION_ISSUE_[TYPE]_[DESC]_[YYYYMMDD].md

Examples:
- INTEGRATION_ISSUE_API_500_SyncEndpoint_20260412.md
- INTEGRATION_ISSUE_AUTH_403_PairingCode_20260412.md

## Mandatory Workflow

### 1) Verify Frontend Is Not Root Cause
- Confirm request construction, headers, auth token handling, and parsing logic
- Confirm issue persists with correct frontend assumptions

### 2) Collect Structured Evidence
- Endpoint, method, headers, body
- Status code, response headers, raw response body
- Repro steps with deterministic conditions

### 3) Fill All Required Sections
Use the project template from integration-issue-documentation.md and complete every required section:
1. Issue Summary
2. Description
3. Steps to Reproduce
4. Request Details
5. Response Details
6. Expected Behavior
7. Frontend Context and Logs
8. Suggested Fix / Next Steps
9. Frontend Remediation Already Done (conditional: include if and only if frontend part existed and is already resolved)

### 4) Add Backend Actionability
- State impact and severity clearly
- Provide concrete backend fix hypothesis
- Include validation criteria for backend team

## Quality Gates
- Report is specific and reproducible
- No sensitive personal data leaked
- Proposed backend next steps are concrete
