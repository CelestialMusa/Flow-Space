# Client Sign-Off Review Feature - Testing Guide

## Prerequisites
- Backend server running on port 3001
- Flutter app running in Chrome
- Valid sign-off report ID in database
- User logged in (for generating review links)

---

## Test Scenario 1: Generate Client Review Link

### Steps:
1. **Login to the app** (if not already logged in)
2. **Navigate to a sign-off report** (you need a report ID)
3. **Generate a review link** using one of these methods:

   **Option A: Using API directly (Postman/Thunder Client)**
   ```http
   POST http://localhost:3001/api/sign-off-reports/client-review-links
   Headers:
     Authorization: Bearer <your_access_token>
     Content-Type: application/json
   Body:
   {
     "reportId": "<report-id-here>",
     "clientEmail": "client@example.com",
     "expiresInSeconds": 604800
   }
   ```

   **Option B: Using Flutter app** (if UI exists)
   - Find the "Generate Review Link" button on a sign-off report
   - Enter client email
   - Click generate

### Expected Result:
- Response contains `linkToken`, `expiresAt`, and `reportId`
- Token is a valid JWT string
- Expiration date is 7 days from now (or custom if specified)

---

## Test Scenario 2: Access Report via Token (No Authentication Required)

### Steps:
1. **Copy the token** from Test Scenario 1
2. **Open a new incognito/private browser window** (to simulate unauthenticated client)
3. **Navigate to**: `http://localhost:<port>/client-review-token/<token>`
   - Replace `<token>` with the actual token
   - Example: `http://localhost:50000/client-review-token/eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

### Expected Result:
- Page loads without requiring login
- Sign-off report content is displayed
- Performance visuals are rendered (if sprint data exists):
  - Velocity trend chart
  - Committed vs Completed bars
  - Burndown/Burnup chart
  - Defect curve
  - Test pass rate
  - Scope change indicators
- "Approve" and "Request Changes" buttons are visible

---

## Test Scenario 3: Approve Report (Happy Path)

### Steps:
1. **On the client review page** (from Test Scenario 2)
2. **Click "Approve" button**
3. **Optional**: Add a comment in the modal
4. **Optional**: Provide a digital signature
5. **Click "Submit" or "Approve"**

### Expected Result:
- Success message displayed
- Report status updates to "approved"
- Deliverable status updates to "approved"
- `approved_at` timestamp is recorded (UTC)
- `approved_by` is recorded (from token)
- Audit trail entry created
- Notification sent to report creator
- Page shows "Approved" status

---

## Test Scenario 4: Request Changes (Happy Path)

### Steps:
1. **On the client review page** (use a different report or reset status)
2. **Click "Request Changes" button**
3. **Enter mandatory comment** (e.g., "Please update the velocity calculations")
4. **Click "Submit"**

### Expected Result:
- Success message displayed
- Report status updates to "change_requested"
- Deliverable status updates to "change_requested"
- `change_request_details` is stored
- Audit trail entry created
- Notifications sent to ALL team members assigned to deliverable
- Page shows "Change Requested" status

---

## Test Scenario 5: Request Changes Without Comment (Validation Test)

### Steps:
1. **On the client review page**
2. **Click "Request Changes" button**
3. **Leave comment field empty**
4. **Try to submit**

### Expected Result:
- **Client-side**: Validation error prevents submission
- **Server-side**: If somehow submitted, returns 400 error:
  ```json
  {
    "error": "changeRequestDetails is required and cannot be empty"
  }
  ```
- Form highlights the required field
- Error message displayed to user

---

## Test Scenario 6: Expired Token

### Steps:
1. **Generate a token with short expiration** (e.g., 10 seconds)
   ```json
   {
     "reportId": "<report-id>",
     "clientEmail": "client@example.com",
     "expiresInSeconds": 10
   }
   ```
2. **Wait 15 seconds**
3. **Try to access the report** using the token

### Expected Result:
- Error message displayed: "This review link is invalid or has expired"
- HTTP 401 status code
- User-friendly error UI shown
- Option to request a new link (if implemented)

---

## Test Scenario 7: Invalid Token

### Steps:
1. **Navigate to**: `http://localhost:<port>/client-review-token/invalid-token-12345`

### Expected Result:
- Error message displayed: "Invalid or expired token"
- HTTP 401 status code
- User-friendly error UI shown

---

## Test Scenario 8: Performance Visuals Rendering

### Prerequisites:
- Sign-off report must have associated sprint IDs
- `sprint_metrics` table must have data

### Steps:
1. **Access a report with sprint data** via token
2. **Scroll through the performance visuals section**

### Expected Result:
- All charts render correctly:
  - ✅ Velocity trend (line chart showing points per sprint)
  - ✅ Committed vs Completed (bar chart)
  - ✅ Burndown chart (line chart showing remaining work over time)
  - ✅ Burnup chart (line chart showing completed work over time)
  - ✅ Defect curve (line chart with severity breakdown)
  - ✅ Test pass rate (percentage display)
  - ✅ Scope change indicators (list of added/removed items)

### If No Sprint Data:
- Graceful fallback message: "No sprint data available"
- Page still loads and functions normally

---

## Test Scenario 9: Network Error Handling

### Steps:
1. **Stop the backend server**
2. **Try to access a report via token**
3. **Try to approve/request changes**

### Expected Result:
- Network error message displayed
- User-friendly error UI
- Option to retry
- No app crash

---

## Test Scenario 10: Audit Trail Verification

### Steps:
1. **Approve or request changes** on a report
2. **Check the audit_logs table** in database:
   ```sql
   SELECT * FROM audit_logs 
   WHERE entity_type = 'signoff' 
   AND entity_id = '<report-id>'
   ORDER BY created_at DESC;
   ```

### Expected Result:
- Audit entry created with:
  - `action`: 'approved' or 'change_requested'
  - `actor_id`: User ID or client ID from token
  - `actor_name`: User name or client email
  - `details`: Contains comment, timestamp, token info
  - `created_at`: UTC timestamp

---

## Test Scenario 11: Notification Verification

### Steps:
1. **Request changes** on a report
2. **Check notifications table** for team members:
   ```sql
   SELECT * FROM notifications 
   WHERE related_entity_type = 'signoff' 
   AND related_entity_id = '<report-id>'
   ORDER BY created_at DESC;
   ```

### Expected Result:
- Notifications created for ALL team members assigned to deliverable:
  - Report creator
  - Deliverable assignee
  - Project owner
  - Other team members (if any)
- Notification message indicates change request
- Notification includes link to report

---

## Quick Test Checklist

- [ ] Generate review link successfully
- [ ] Access report via token (no login required)
- [ ] Performance visuals render correctly
- [ ] Approve report with optional comment
- [ ] Approve report without comment
- [ ] Request changes with mandatory comment
- [ ] Request changes without comment (validation fails)
- [ ] Expired token shows error
- [ ] Invalid token shows error
- [ ] Network errors handled gracefully
- [ ] Audit trail entries created
- [ ] Notifications sent to team members
- [ ] UTC timestamps recorded correctly
- [ ] Digital signature stored (if provided)

---

## Troubleshooting

### Issue: Token generation fails
- **Check**: User is authenticated
- **Check**: Report ID exists in database
- **Check**: Backend server is running
- **Check**: Database connection is working

### Issue: Report not loading via token
- **Check**: Token is not expired
- **Check**: Token format is correct (JWT)
- **Check**: Report exists in database
- **Check**: Backend endpoint is accessible

### Issue: Performance visuals not showing
- **Check**: Report has associated sprint IDs
- **Check**: `sprint_metrics` table has data
- **Check**: Browser console for JavaScript errors
- **Check**: `fl_chart` package is installed

### Issue: Approve/Request Changes fails
- **Check**: Token is valid and not expired
- **Check**: Network connection
- **Check**: Backend server logs for errors
- **Check**: Database constraints (foreign keys, etc.)

---

## Database Queries for Testing

### Find a sign-off report ID:
```sql
SELECT id, deliverable_id, status, created_at 
FROM sign_off_reports 
ORDER BY created_at DESC 
LIMIT 5;
```

### Check report status after approval:
```sql
SELECT id, status, approved_at, approved_by, change_request_details
FROM sign_off_reports
WHERE id = '<report-id>';
```

### Check deliverable status:
```sql
SELECT id, title, status
FROM deliverables
WHERE id = '<deliverable-id>';
```

### Check audit logs:
```sql
SELECT action, actor_name, details, created_at
FROM audit_logs
WHERE entity_type = 'signoff'
AND entity_id = '<report-id>'
ORDER BY created_at DESC;
```

