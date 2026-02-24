# ⚡ Quick Test Checklist - Flow-Space App

## 🎯 Priority 1: Critical Features (Test These First - 30 minutes)

### ✅ Authentication
- [ ] Login works
- [ ] Logout works
- [ ] Email verification works (if testing registration)

### ✅ Sprint Creation
- [ ] Navigate to `/sprint-console`
- [ ] Click "Create Sprint"
- [ ] Fill: Name, Start Date, End Date
- [ ] **Expected**: Sprint created, appears in list
- [ ] **Verify**: No errors in console

### ✅ Deliverable Creation
- [ ] Navigate to `/enhanced-deliverable-setup`
- [ ] Fill: Title, Description, Project, Priority, Due Date
- [ ] Link Sprint (select sprint from Test 1)
- [ ] Add Definition of Done items
- [ ] **Upload File** (critical test):
  - Click "Add Document"
  - Select file (PDF/image)
  - **Expected**: File uploads WITHOUT "path unavailable" error
- [ ] Click "Create Deliverable"
- [ ] **Expected**: Deliverable created, redirects to detail page

### ✅ Sign-Off Report Creation
- [ ] On deliverable detail page
- [ ] Click "Create Sign-Off Report"
- [ ] Fill report content
- [ ] Click "Create"
- [ ] **Expected**: Report created, status "draft"

### ✅ Client Review Link Generation
- [ ] On report page, click "Generate Review Link"
- [ ] Enter email: `client@test.com`
- [ ] Set expiration: 7 days
- [ ] Click "Generate"
- [ ] **Copy the link** (you'll need it)

### ✅ Token-Based Client Review (No Login Required)
- [ ] **Open incognito/private browser window**
- [ ] Paste the review link from previous step
- [ ] Navigate to link
- [ ] **Expected**: 
  - ✅ Page loads WITHOUT login
  - ✅ Report content displays
  - ✅ Performance visuals render (if sprint data exists)
  - ✅ "Approve" and "Request Changes" buttons visible

### ✅ Approve Report (via Token)
- [ ] On review page, click "Approve"
- [ ] Add optional comment: "Looks good"
- [ ] Click "Submit"
- [ ] **Expected**: 
  - ✅ Success message
  - ✅ Report status: "approved"
  - ✅ Deliverable status: "approved"

### ✅ Request Changes (with Validation)
- [ ] Create another report and generate link
- [ ] Access link in incognito
- [ ] Click "Request Changes"
- [ ] **Test Validation**: Try submitting WITHOUT comment
  - **Expected**: Error "Comment is required"
- [ ] Add comment: "Please update calculations"
- [ ] Submit
- [ ] **Expected**: 
  - ✅ Success message
  - ✅ Report status: "change_requested"
  - ✅ Team members notified

---

## 🎯 Priority 2: Role-Based Tests (45 minutes)

### System Admin
- [ ] Login as System Admin
- [ ] Access `/role-management` → **Expected**: Can access
- [ ] Access `/audit-logs` → **Expected**: Can access
- [ ] Create user → **Expected**: Works
- [ ] Edit user role → **Expected**: Works

### Delivery Lead
- [ ] Login as Delivery Lead
- [ ] Create project → **Expected**: Works
- [ ] Create sprint → **Expected**: Works
- [ ] Submit deliverable for review → **Expected**: Works
- [ ] Generate review link → **Expected**: Works

### Team Member
- [ ] Login as Team Member
- [ ] Create deliverable → **Expected**: Works
- [ ] Try to access `/role-management` → **Expected**: Permission denied/hidden
- [ ] View own deliverables → **Expected**: Only own deliverables visible

### Client Reviewer
- [ ] Login as Client Reviewer
- [ ] Access `/approval-requests` → **Expected**: Can see pending reviews
- [ ] Approve report → **Expected**: Works
- [ ] Request changes → **Expected**: Works

---

## 🎯 Priority 3: Feature Tests (30 minutes)

### Projects
- [ ] Create project
- [ ] Edit project
- [ ] Add project members
- [ ] View project details

### Sprints
- [ ] View sprint board (Kanban)
- [ ] Drag ticket between columns → **Expected**: Status updates
- [ ] View sprint metrics → **Expected**: Charts render
- [ ] Update sprint status → **Expected**: Status saves

### Notifications
- [ ] Navigate to `/notifications`
- [ ] **Expected**: Notifications list displays
- [ ] Click notification → **Expected**: Marked as read

### Timeline
- [ ] Navigate to `/timeline`
- [ ] **Expected**: Calendar view displays
- [ ] Switch month/week view → **Expected**: Works

### Repository
- [ ] Navigate to `/repository`
- [ ] Upload document → **Expected**: Works
- [ ] Download document → **Expected**: Works

---

## 🎯 Priority 4: Error Scenarios (15 minutes)

### Validation Errors
- [ ] Try to create sprint without name → **Expected**: Validation error
- [ ] Try to create deliverable without project → **Expected**: Validation error
- [ ] Try to request changes without comment → **Expected**: Validation error

### Token Errors
- [ ] Try invalid token URL → **Expected**: Error message
- [ ] Try expired token → **Expected**: Error message

### Permission Errors
- [ ] Team Member tries to access admin features → **Expected**: Permission denied

---

## 📊 Test Results Summary

### ✅ Passed Tests: ___ / ___
### ❌ Failed Tests: ___ / ___
### ⚠️  Warnings: ___ / ___

### Critical Bugs Found:
1. [ ] Bug 1: ________________________
2. [ ] Bug 2: ________________________
3. [ ] Bug 3: ________________________

### Notes:
- Backend URL: `http://localhost:3001`
- Frontend URL: `http://localhost:<port>`
- Test Date: _______________
- Tester: _______________

---

## 🚨 If Tests Fail

1. **Check Browser Console (F12)**
   - Look for JavaScript errors
   - Copy error messages

2. **Check Network Tab**
   - Look for failed API calls (red)
   - Check request/response details

3. **Check Backend Logs**
   - Look for server errors
   - Check database connection

4. **Document the Issue**
   - Screenshot the error
   - Note which step failed
   - Copy exact error message

---

**Quick Test Time: ~2 hours for all priorities**

