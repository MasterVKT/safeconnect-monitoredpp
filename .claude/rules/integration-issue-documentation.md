# Integration Issue Documentation Template

This document provides a template for reporting integration issues found during development. When an AI agent detects an issue (e.g., a backend API error, unexpected data format, CORS problem), it should automatically create a new file based on this template.

## How to Use
1.  **Create a new file**: `docs/integration_issues/INTEGRATION_ISSUE_[TYPE]_[DESC]_[YYYYMMDD].md`
    - `[TYPE]`: The type of error (e.g., `API_500`, `DATA_MISMATCH`, `AUTH_403`).
    - `[DESC]`: A very short, one-or-two-word description (e.g., `GetUserEndpoint`, `SmsFormat`).
    - `[YYYYMMDD]`: The current date.
2.  **Fill out all required sections** of the template below.
3.  **Section 9 is conditional but mandatory when applicable**: include it only if part of the issue concerned frontend and this frontend part has already been resolved.

---

## 1. Issue Summary
- **Type**: (e.g., Backend API Error, Data Format Mismatch, Authentication Failure)
- **Endpoint/Feature**: (e.g., `/api/v1/users/me`, SMS Data Collector)
- **Severity**: (e.g., Critical, High, Medium, Low)
- **One-Line Summary**: A concise summary of the problem.

## 2. Description
A detailed, clear description of the issue. What happened? What was expected?

## 3. Steps to Reproduce
1.  (Action 1, e.g., "Navigated to the profile screen")
2.  (Action 2, e.g., "The app called the `/api/v1/users/me` endpoint")
3.  (Result, e.g., "The endpoint returned a 500 Internal Server Error instead of the user object")

## 4. Request Details (if applicable)
- **Endpoint**:
- **Method**: (e.g., GET, POST)
- **Headers**:
  ```json
  {
    "Authorization": "Bearer <token>",
    "Content-Type": "application/json"
  }
  ```
- **Body**:
  ```json
  {
    "key": "value"
  }
  ```

## 5. Response Details (if applicable)
- **Status Code**: (e.g., 500)
- **Headers**:
  ```json
  {
    "Content-Type": "application/json"
  }
  ```
- **Body (Raw)**:
  ```json
  // The raw JSON response from the server
  {
    "error": "Internal Server Error",
    "message": "A database connection could not be established."
  }
  ```

## 6. Expected Behavior
A clear description of what the expected outcome should have been. For example, "The API should have returned a 200 OK status with a JSON body containing the user's profile information."

## 7. Frontend Context & Logs
Any relevant logs, screenshots, or code snippets from the frontend application that help diagnose the issue.

```dart
// Code snippet from the frontend that made the call
try {
  final response = await _dio.get('/api/v1/users/me');
} catch (e) {
  // e.response contains the error details above
  log(e.toString());
}
```

## 8. Suggested Fix / Next Steps
A preliminary analysis of the problem and a suggested solution or next steps for the backend team. For example: "It appears the database connection on the server is failing. Please check the server logs for details on the DB connection pool."

## 9. Frontend Remediation Already Done (Conditional)
Include this section **if and only if** a frontend part of the issue existed and has already been resolved.

- **Was frontend impacted?**: Yes/No
- **Was frontend fix completed?**: Yes/No
- **Files changed (frontend)**: List exact file paths
- **Detailed frontend changes**: Precise and complete description of what was implemented
- **Validation performed on frontend**: Tests/checks/manual verification already completed
- **Remaining backend dependency**: Explain why backend changes are still required despite frontend remediation
