# 🧪 Comprehensive Test Plan - Flow-Space Application

## 📋 Table of Contents
1. [Test Setup & Prerequisites](#test-setup--prerequisites)
2. [User Roles Overview](#user-roles-overview)
3. [Test Scenarios by Role](#test-scenarios-by-role)
4. [Feature-Specific Tests](#feature-specific-tests)
5. [Integration Tests](#integration-tests)
6. [Security & Permission Tests](#security--permission-tests)
7. [Error Handling Tests](#error-handling-tests)
8. [Performance Tests](#performance-tests)

---

## 🚀 Test Setup & Prerequisites

### Before Starting
- ✅ Backend server running on `http://localhost:3001`
- ✅ Flutter app running in Chrome
- ✅ Database tables created (run `node backend/migrations/ensure_missing_tables_fullscan.cjs` if needed)
- ✅ Browser DevTools open (F12) to monitor console errors
- ✅ Network tab open to monitor API calls

### Test Data Preparation
Create test users for each role (or use existing):
- **System Admin**: `admin@test.com` / `password123`
- **Delivery Lead**: `lead@test.com` / `password123`
- **Team Member**: `member@test.com` / `password123`
- **Client Reviewer**: `client@test.com` / `password123`
- **Project Manager**: `pm@test.com` / `password123`
- **Developer**: `dev@test.com` / `password123`
- **Scrum Master**: `scrum@test.com` / `password123`
- **QA Engineer**: `qa@test.com` / `password123`
- **Stakeholder**: `stakeholder@test.com` / `password123`
- **Client**: `clientuser@test.com` / `password123`

---

## 👥 User Roles Overview

| Role | Key Permissions | Primary Functions |
|------|----------------|-------------------|
| **System Admin** | All permissions | Manage users, view audit logs, system configuration |
| **Delivery Lead** | Manage sprints, submit for review, override gates | Team management, client review submission |
| **Team Member** | Create/edit deliverables, view sprints, update tickets | Create work, track progress |
| **Client Reviewer** | Approve deliverables, view client review | Review and approve deliverables |
| **Client** | View client review, approve deliverables | Review deliverables |
| **Project Manager** | Manage projects, view team dashboard | Project oversight |
| **Developer** | Create deliverables, view sprints | Development work |
| **Scrum Master** | Manage sprints, view team dashboard | Agile facilitation |
| **QA Engineer** | Create deliverables, view all deliverables | Quality assurance |
| **Stakeholder** | View all deliverables, approve deliverables | Business oversight |

---

## 🎯 Test Scenarios by Role

### 1. SYSTEM ADMIN Tests

#### Test 1.1: Login & Dashboard Access
**Steps:**
1. Navigate to `/login`
2. Login as System Admin
3. **Expected**: Redirected to `/dashboard` or `/system-admin-dashboard`
4. **Verify**: 
   - ✅ Dashboard loads with admin-specific widgets
   - ✅ Sidebar shows all menu items (including Role Management, Audit Logs)
   - ✅ User name and role displayed correctly

#### Test 1.2: User & Role Management
**Steps:**
1. Click **"Role Management"** in sidebar
2. **Expected**: Role Management screen loads
3. **Test Create User:**
   - Click **"Add User"** or **"Create User"**
   - Fill form: Name, Email, Role (select "Team Member")
   - Click **"Save"**
   - **Expected**: User created, appears in list
4. **Test Edit User:**
   - Click on a user in the list
   - Change role to "Delivery Lead"
   - Click **"Save"**
   - **Expected**: Role updated successfully
5. **Test Delete User:**
   - Click delete/remove on a test user
   - Confirm deletion
   - **Expected**: User removed from list

#### Test 1.3: Audit Logs Access
**Steps:**
1. Click **"Audit Logs"** in sidebar (or navigate to `/audit-logs`)
2. **Expected**: Audit logs screen loads
3. **Verify**:
   - ✅ Logs display in chronological order
   - ✅ Filters work (date range, user, action type)
   - ✅ Export functionality works (if available)

#### Test 1.4: System Metrics & Health
**Steps:**
1. Navigate to `/system-metrics`
2. **Expected**: System metrics dashboard loads
3. Navigate to `/system-health`
4. **Expected**: System health status displays
5. **Verify**: All metrics render correctly

#### Test 1.5: Full Feature Access
**Steps:**
1. Test access to ALL screens:
   - ✅ Projects (`/projects`)
   - ✅ Sprints (`/sprint-console`)
   - ✅ Deliverables (`/deliverables`)
   - ✅ Reports (`/report-repository`)
   - ✅ Notifications (`/notifications`)
   - ✅ Timeline (`/timeline`)
   - ✅ Settings (`/settings`)
   - ✅ Profile (`/profile`)
2. **Expected**: All screens accessible (no permission errors)

---

### 2. DELIVERY LEAD Tests

#### Test 2.1: Login & Dashboard
**Steps:**
1. Login as Delivery Lead
2. **Expected**: Redirected to `/dashboard` or `/delivery-manager-dashboard`
3. **Verify**: Dashboard shows team performance metrics

#### Test 2.2: Create & Manage Projects
**Steps:**
1. Navigate to `/projects`
2. Click **"Create Project"** or **"+"**
3. Fill form:
   - **Name**: "Test Project - Delivery Lead"
   - **Description**: "Testing project creation"
   - **Start Date**: Today
   - **End Date**: 3 months from today
4. Click **"Create"**
5. **Expected**: Project created, appears in list
6. **Test Edit Project:**
   - Click on project
   - Edit description
   - Save
   - **Expected**: Changes saved

#### Test 2.3: Create & Manage Sprints
**Steps:**
1. Navigate to `/sprint-console`
2. Click **"Create Sprint"** or **"+"**
3. Fill form:
   - **Name**: "Sprint 1 - Feb 2026"
   - **Start Date**: Today
   - **End Date**: 2 weeks from today
   - **Project**: Select test project
   - **Planned Points**: 20
4. Click **"Create"**
5. **Expected**: Sprint created successfully
6. **Test Sprint Board:**
   - Click on sprint
   - Navigate to Sprint Board
   - **Expected**: Kanban board displays with columns (To Do, In Progress, Done)
7. **Test Update Sprint Status:**
   - Change sprint status from "planning" to "active"
   - **Expected**: Status updates, saved to database

#### Test 2.4: Create Deliverable
**Steps:**
1. Navigate to `/enhanced-deliverable-setup`
2. Fill form:
   - **Title**: "API Integration Module"
   - **Description**: "Complete REST API integration"
   - **Project**: Select test project
   - **Priority**: High
   - **Due Date**: 1 month from today
3. **Link Sprint:**
   - Scroll to "Contributing Sprints"
   - Select the sprint created in Test 2.3
4. **Add Definition of Done:**
   - Add 3-4 DoD items
5. **Add Evidence Links:**
   - Add repository link
6. **Upload File:**
   - Click "Add Document"
   - Select a file (PDF, image, etc.)
   - **Expected**: File uploads without "path unavailable" error
7. Click **"Create Deliverable"**
8. **Expected**: Deliverable created, redirects to detail page

#### Test 2.5: Submit for Client Review
**Steps:**
1. Navigate to deliverable detail page
2. Click **"Create Sign-Off Report"** or **"Generate Report"**
3. Fill report details
4. Click **"Submit for Review"**
5. **Expected**: 
   - ✅ Report status changes to "pending_review"
   - ✅ Deliverable status updates
   - ✅ Notification sent to client reviewers

#### Test 2.6: Generate Client Review Link
**Steps:**
1. On sign-off report page, click **"Generate Review Link"** or **"Share with Client"**
2. Enter client email: `client@test.com`
3. Set expiration: 7 days
4. Click **"Generate"**
5. **Expected**: 
   - ✅ Token/link generated
   - ✅ Link displayed (copy it)
   - ✅ Expiration date shown
6. **Copy the link** for Test 2.7

#### Test 2.7: View Team Dashboard
**Steps:**
1. Navigate to `/dashboard`
2. **Expected**: 
   - ✅ Team performance metrics display
   - ✅ Sprint velocity charts
   - ✅ Deliverable status overview
   - ✅ Upcoming deadlines

---

### 3. TEAM MEMBER Tests

#### Test 3.1: Login & Dashboard
**Steps:**
1. Login as Team Member
2. **Expected**: Redirected to `/dashboard`
3. **Verify**: Dashboard shows personal work items

#### Test 3.2: View Sprints
**Steps:**
1. Navigate to `/sprint-console`
2. **Expected**: List of sprints displays
3. **Verify**: Can view sprint details (read-only for some fields)

#### Test 3.3: Create Deliverable
**Steps:**
1. Navigate to `/enhanced-deliverable-setup`
2. Create a deliverable (same as Test 2.4)
3. **Expected**: Deliverable created successfully
4. **Verify**: Can edit own deliverables

#### Test 3.4: Update Ticket Status
**Steps:**
1. Navigate to Sprint Board (`/sprint-board/:sprintId`)
2. Find a ticket assigned to you
3. Drag ticket from "To Do" to "In Progress"
4. **Expected**: Ticket status updates
5. Drag to "Done"
6. **Expected**: Ticket marked complete

#### Test 3.5: View Own Deliverables
**Steps:**
1. Navigate to `/deliverables` or `/deliverables-overview`
2. **Expected**: Only deliverables you created/assigned to you are visible
3. **Verify**: Cannot see other team members' private deliverables

#### Test 3.6: Access Restrictions
**Steps:**
1. Try to access:
   - `/role-management` → **Expected**: Permission denied or hidden
   - `/audit-logs` → **Expected**: Permission denied or hidden
   - `/system-metrics` → **Expected**: Permission denied or hidden
2. **Verify**: Cannot access admin-only features

---

### 4. CLIENT REVIEWER Tests

#### Test 4.1: Login & Dashboard
**Steps:**
1. Login as Client Reviewer
2. **Expected**: Redirected to `/client-reviewer-dashboard`
3. **Verify**: Dashboard shows pending reviews

#### Test 4.2: View Approval Requests
**Steps:**
1. Navigate to `/approval-requests`
2. **Expected**: List of pending approval requests
3. **Verify**: Can see deliverable details, report links

#### Test 4.3: Review Sign-Off Report (Authenticated)
**Steps:**
1. Click on a sign-off report from approval requests
2. Navigate to `/client-review/:reportId`
3. **Expected**: 
   - ✅ Report content displays
   - ✅ Performance visuals render (velocity, burndown, etc.)
   - ✅ "Approve" and "Request Changes" buttons visible

#### Test 4.4: Approve Report
**Steps:**
1. On client review page, click **"Approve"**
2. **Optional**: Add comment "Approved, looks good"
3. **Optional**: Provide digital signature
4. Click **"Submit"**
5. **Expected**: 
   - ✅ Success message
   - ✅ Report status: "approved"
   - ✅ Deliverable status: "approved"
   - ✅ Timestamp recorded
   - ✅ Notification sent to delivery lead

#### Test 4.5: Request Changes
**Steps:**
1. Navigate to another sign-off report
2. Click **"Request Changes"**
3. **Test Validation**: Try submitting without comment
   - **Expected**: Error "Comment is required"
4. Add comment: "Please update velocity calculations"
5. Click **"Submit"**
6. **Expected**: 
   - ✅ Success message
   - ✅ Report status: "change_requested"
   - ✅ Deliverable status: "change_requested"
   - ✅ Team members notified

#### Test 4.6: Token-Based Review (Unauthenticated)
**Steps:**
1. **Open incognito/private browser window**
2. Paste the review link from Test 2.6
3. Navigate to: `http://localhost:<port>/client-review-token/<token>`
4. **Expected**: 
   - ✅ Page loads WITHOUT login
   - ✅ Report content displays
   - ✅ Performance visuals render
   - ✅ Can approve or request changes
5. **Test Approve via Token:**
   - Click "Approve"
   - Add comment
   - Submit
   - **Expected**: Works without authentication

---

### 5. CLIENT Tests

#### Test 5.1: Token-Based Access Only
**Steps:**
1. **Note**: Clients typically don't have app login
2. Use token-based review link (from Test 2.6)
3. **Expected**: Can access review page without login
4. **Verify**: Cannot access other app features

#### Test 5.2: Review & Approve
**Steps:**
1. Access review link
2. Review report content
3. Approve or request changes
4. **Expected**: Actions work correctly

---

### 6. PROJECT MANAGER Tests

#### Test 6.1: Login & Dashboard
**Steps:**
1. Login as Project Manager
2. **Expected**: Dashboard shows project overview

#### Test 6.2: Manage Projects
**Steps:**
1. Navigate to `/projects`
2. Create, edit, delete projects
3. **Expected**: Full project management access

#### Test 6.3: View Team Dashboard
**Steps:**
1. Navigate to `/dashboard`
2. **Expected**: Team performance metrics visible

#### Test 6.4: Submit for Review
**Steps:**
1. Create deliverable
2. Submit for client review
3. **Expected**: Can submit (has `submit_for_review` permission)

---

### 7. DEVELOPER Tests

#### Test 7.1: Create Deliverables
**Steps:**
1. Login as Developer
2. Create deliverable
3. **Expected**: Can create and edit deliverables

#### Test 7.2: View Sprints
**Steps:**
1. Navigate to `/sprint-console`
2. **Expected**: Can view sprints

#### Test 7.3: Update Tickets
**Steps:**
1. Navigate to Sprint Board
2. Update ticket status
3. **Expected**: Can move tickets

---

### 8. SCRUM MASTER Tests

#### Test 8.1: Manage Sprints
**Steps:**
1. Login as Scrum Master
2. Navigate to `/sprint-console`
3. Create and manage sprints
4. **Expected**: Full sprint management access

#### Test 8.2: View Team Dashboard
**Steps:**
1. Navigate to `/dashboard`
2. **Expected**: Team metrics visible

#### Test 8.3: Submit for Review
**Steps:**
1. Submit deliverable for review
2. **Expected**: Can submit (has permission)

---

### 9. QA ENGINEER Tests

#### Test 9.1: Create Deliverables
**Steps:**
1. Login as QA Engineer
2. Create deliverable (test plan, test results)
3. **Expected**: Can create deliverables

#### Test 9.2: View All Deliverables
**Steps:**
1. Navigate to `/deliverables-overview`
2. **Expected**: Can see all team deliverables

---

### 10. STAKEHOLDER Tests

#### Test 10.1: View Deliverables
**Steps:**
1. Login as Stakeholder
2. Navigate to `/deliverables-overview`
3. **Expected**: Can view all deliverables (read-only)

#### Test 10.2: Approve Deliverables
**Steps:**
1. Navigate to approval requests
2. Approve deliverable
3. **Expected**: Can approve (has permission)

---

## 🔧 Feature-Specific Tests

### A. Authentication & Authorization

#### Test A.1: User Registration
**Steps:**
1. Navigate to `/register`
2. Fill form:
   - Email: `newuser@test.com`
   - Password: `password123`
   - Name: "New User"
   - Role: Select "Team Member"
3. Click **"Register"**
4. **Expected**: 
   - ✅ Registration successful
   - ✅ Redirected to email verification
   - ✅ Email sent (check backend logs)

#### Test A.2: Email Verification
**Steps:**
1. After registration, navigate to `/verify-email`
2. Enter verification code (from email or backend logs)
3. Click **"Verify"**
4. **Expected**: 
   - ✅ Email verified
   - ✅ Redirected to login
   - ✅ Can now login

#### Test A.3: Login
**Steps:**
1. Navigate to `/login`
2. Enter credentials
3. Click **"Login"**
4. **Expected**: 
   - ✅ Login successful
   - ✅ JWT token stored
   - ✅ Redirected to role-appropriate dashboard

#### Test A.4: Logout
**Steps:**
1. Click logout button (sidebar or profile)
2. **Expected**: 
   - ✅ Logged out
   - ✅ Token cleared
   - ✅ Redirected to login

#### Test A.5: Token Refresh
**Steps:**
1. Login
2. Wait for token to expire (or manually expire)
3. Make API call
4. **Expected**: Token refreshed automatically (if implemented)

---

### B. Projects Feature

#### Test B.1: Create Project
**Steps:**
1. Navigate to `/projects`
2. Click **"Create Project"**
3. Fill all fields
4. Click **"Create"**
5. **Expected**: Project created, appears in list

#### Test B.2: Edit Project
**Steps:**
1. Click on project
2. Edit details
3. Save
4. **Expected**: Changes saved

#### Test B.3: Delete Project
**Steps:**
1. Click delete on test project
2. Confirm
3. **Expected**: Project deleted

#### Test B.4: Project Members
**Steps:**
1. Navigate to project detail
2. Go to "Members" tab
3. Add member
4. **Expected**: Member added
5. Change member role
6. **Expected**: Role updated
7. Remove member
8. **Expected**: Member removed

---

### C. Sprints Feature

#### Test C.1: Create Sprint
**Steps:**
1. Navigate to `/sprint-console`
2. Create sprint (see Test 2.3)
3. **Expected**: Sprint created

#### Test C.2: Sprint Board (Kanban)
**Steps:**
1. Navigate to `/sprint-board/:sprintId`
2. **Expected**: 
   - ✅ Kanban board displays
   - ✅ Columns: To Do, In Progress, Done (or similar)
   - ✅ Tickets display in correct columns
3. **Test Drag & Drop:**
   - Drag ticket to different column
   - **Expected**: Status updates, saved to database

#### Test C.3: Sprint Metrics
**Steps:**
1. Navigate to `/sprint-metrics/:sprintId`
2. **Expected**: 
   - ✅ Velocity chart displays
   - ✅ Burndown chart displays
   - ✅ Burnup chart displays
   - ✅ Defect curve displays
   - ✅ Test pass rate displays
   - ✅ Scope change indicator displays

#### Test C.4: Update Sprint Status
**Steps:**
1. On sprint detail page
2. Change status: planning → active → completed
3. **Expected**: Status updates, saved

---

### D. Deliverables Feature

#### Test D.1: Create Deliverable
**Steps:**
1. Navigate to `/enhanced-deliverable-setup`
2. Fill all sections:
   - Basic info
   - Link sprints
   - Definition of Done
   - Evidence links
   - Attachments (file upload)
3. Click **"Create"**
4. **Expected**: Deliverable created

#### Test D.2: File Upload (Web)
**Steps:**
1. On deliverable setup screen
2. Click **"Add Document"**
3. Select file (PDF, image, etc.)
4. **Expected**: 
   - ✅ File picker opens
   - ✅ File selected
   - ✅ File uploads (no "path unavailable" error)
   - ✅ File appears in attachments list

#### Test D.3: Edit Deliverable
**Steps:**
1. Navigate to deliverable detail
2. Click **"Edit"**
3. Modify fields
4. Save
5. **Expected**: Changes saved

#### Test D.4: Link Multiple Sprints
**Steps:**
1. Create deliverable
2. Link 2-3 sprints
3. **Expected**: All sprints linked correctly

---

### E. Sign-Off Reports Feature

#### Test E.1: Create Sign-Off Report
**Steps:**
1. Navigate to deliverable detail
2. Click **"Create Sign-Off Report"**
3. Fill report content
4. Click **"Create"**
5. **Expected**: Report created, status "draft"

#### Test E.2: Generate Client Review Link
**Steps:**
1. On report page, click **"Generate Review Link"**
2. Enter client email
3. Set expiration (7 days)
4. Click **"Generate"**
5. **Expected**: 
   - ✅ Link generated
   - ✅ Token created
   - ✅ Expiration set

#### Test E.3: Token-Based Access
**Steps:**
1. **Open incognito window**
2. Paste review link
3. Navigate to link
4. **Expected**: 
   - ✅ Page loads without login
   - ✅ Report displays
   - ✅ Performance visuals render

#### Test E.4: Approve Report
**Steps:**
1. On review page, click **"Approve"**
2. Add optional comment
3. Submit
4. **Expected**: 
   - ✅ Report approved
   - ✅ Status updated
   - ✅ Timestamp recorded
   - ✅ Notification sent

#### Test E.5: Request Changes
**Steps:**
1. Click **"Request Changes"**
2. **Test Validation**: Submit without comment
   - **Expected**: Error "Comment is required"
3. Add comment
4. Submit
5. **Expected**: 
   - ✅ Changes requested
   - ✅ Status updated
   - ✅ Team notified

---

### F. Notifications Feature

#### Test F.1: View Notifications
**Steps:**
1. Navigate to `/notifications`
2. **Expected**: List of notifications displays

#### Test F.2: Notification Types
**Verify notifications for:**
- ✅ Deliverable created
- ✅ Report submitted for review
- ✅ Report approved
- ✅ Changes requested
- ✅ Sprint status changed
- ✅ Ticket assigned

#### Test F.3: Mark as Read
**Steps:**
1. Click on notification
2. **Expected**: Marked as read

---

### G. Timeline Feature

#### Test G.1: View Timeline
**Steps:**
1. Navigate to `/timeline`
2. **Expected**: 
   - ✅ Calendar view displays
   - ✅ Events show on dates
   - ✅ Can switch between month/week views

#### Test G.2: Filter Events
**Steps:**
1. Filter by project, sprint, deliverable
2. **Expected**: Events filter correctly

---

### H. Repository Feature

#### Test H.1: View Repository
**Steps:**
1. Navigate to `/repository`
2. **Expected**: 
   - ✅ Documents list displays
   - ✅ Can filter by type, project, date

#### Test H.2: Upload Document
**Steps:**
1. Click **"Upload Document"**
2. Select file
3. Fill metadata
4. Upload
5. **Expected**: Document uploaded, appears in list

#### Test H.3: Download Document
**Steps:**
1. Click on document
2. Click **"Download"**
3. **Expected**: File downloads

---

### I. Reports Feature

#### Test I.1: View Reports
**Steps:**
1. Navigate to `/report-repository`
2. **Expected**: List of sign-off reports

#### Test I.2: Export Report
**Steps:**
1. Click on report
2. Click **"Export"** (PDF, Excel, etc.)
3. **Expected**: Report exported

---

### J. Profile & Settings

#### Test J.1: View Profile
**Steps:**
1. Navigate to `/profile`
2. **Expected**: Profile information displays

#### Test J.2: Edit Profile
**Steps:**
1. Click **"Edit"**
2. Update name, email, etc.
3. Save
4. **Expected**: Changes saved

#### Test J.3: Upload Profile Picture
**Steps:**
1. Click **"Upload Picture"**
2. Select image
3. Upload
4. **Expected**: Picture updated

#### Test J.4: Settings
**Steps:**
1. Navigate to `/settings`
2. **Expected**: Settings options display
3. Change settings
4. Save
5. **Expected**: Settings saved

---

## 🔗 Integration Tests

### Test INT.1: Complete Workflow
**Scenario**: Team Member creates deliverable → Delivery Lead submits for review → Client Reviewer approves

**Steps:**
1. **Team Member:**
   - Login as Team Member
   - Create deliverable
   - Link to sprint
   - Upload files
   - Save
2. **Delivery Lead:**
   - Login as Delivery Lead
   - View deliverable
   - Create sign-off report
   - Generate review link
   - Submit for review
3. **Client Reviewer:**
   - Use review link (incognito)
   - Review report
   - Approve
4. **Verify:**
   - ✅ Deliverable status: "approved"
   - ✅ Report status: "approved"
   - ✅ Notifications sent
   - ✅ Audit trail created

---

### Test INT.2: Sprint → Deliverable → Report Flow
**Steps:**
1. Create sprint
2. Create deliverable linked to sprint
3. Create sign-off report
4. Generate review link
5. Approve report
6. **Verify**: All entities linked correctly

---

## 🔒 Security & Permission Tests

### Test SEC.1: Unauthorized Access
**Steps:**
1. **Without Login:**
   - Try to access `/dashboard`
   - **Expected**: Redirected to `/login`
2. **With Wrong Role:**
   - Login as Team Member
   - Try to access `/role-management`
   - **Expected**: Permission denied or hidden

### Test SEC.2: Token Validation
**Steps:**
1. Generate review link
2. **Test Expired Token:**
   - Wait for expiration (or manually expire)
   - Try to access link
   - **Expected**: Error "Token expired"
3. **Test Invalid Token:**
   - Modify token in URL
   - Try to access
   - **Expected**: Error "Invalid token"

### Test SEC.3: Data Isolation
**Steps:**
1. Login as Team Member
2. View deliverables
3. **Expected**: Only own deliverables visible
4. Try to access other user's deliverable directly (via URL)
5. **Expected**: Permission denied or not found

---

## ⚠️ Error Handling Tests

### Test ERR.1: Network Errors
**Steps:**
1. Stop backend server
2. Try to create deliverable
3. **Expected**: Error message displayed, app doesn't crash

### Test ERR.2: Validation Errors
**Steps:**
1. Try to create sprint without name
2. **Expected**: Validation error, form highlights field
3. Try to create deliverable without project
4. **Expected**: Validation error

### Test ERR.3: File Upload Errors
**Steps:**
1. Try to upload very large file (>10MB)
2. **Expected**: Error message or size limit warning
3. Try to upload invalid file type
4. **Expected**: Error message

---

## ⚡ Performance Tests

### Test PERF.1: Large Data Sets
**Steps:**
1. Create 50+ sprints
2. Create 100+ deliverables
3. **Expected**: Lists load in reasonable time (<3 seconds)

### Test PERF.2: Concurrent Users
**Steps:**
1. Open app in multiple browser tabs
2. Perform actions simultaneously
3. **Expected**: No conflicts, data consistent

---

## ✅ Test Checklist Summary

### Critical Path Tests (Must Pass)
- [ ] Login/Logout
- [ ] Create Sprint
- [ ] Create Deliverable (with file upload)
- [ ] Create Sign-Off Report
- [ ] Generate Review Link
- [ ] Token-Based Access (no login)
- [ ] Approve Report
- [ ] Request Changes (with validation)
- [ ] Notifications sent
- [ ] Audit trail created

### Role-Based Tests (Must Pass)
- [ ] System Admin: All features accessible
- [ ] Delivery Lead: Can submit for review
- [ ] Team Member: Can create deliverables, restricted from admin features
- [ ] Client Reviewer: Can approve/reject
- [ ] Client: Token-based access only

### Feature Tests (Must Pass)
- [ ] Projects: Create, edit, delete
- [ ] Sprints: Create, board, metrics
- [ ] Deliverables: Create, edit, file upload
- [ ] Reports: Create, approve, request changes
- [ ] Notifications: Receive, view, mark read
- [ ] Timeline: View, filter
- [ ] Repository: Upload, download

---

## 📝 Notes

- **Test Duration**: Full test suite ~2-3 hours
- **Priority**: Focus on Critical Path Tests first
- **Documentation**: Document any bugs found with:
  - Steps to reproduce
  - Expected vs. Actual behavior
  - Screenshots
  - Browser console errors
  - Network request/response logs

---

## 🐛 Bug Reporting Template

```
**Bug Title**: [Brief description]

**Role**: [Which role were you testing as?]

**Steps to Reproduce**:
1. Step 1
2. Step 2
3. Step 3

**Expected Behavior**: [What should happen]

**Actual Behavior**: [What actually happened]

**Screenshots**: [If applicable]

**Console Errors**: [Copy from browser console]

**Network Errors**: [Copy from network tab]

**Environment**:
- Browser: [Chrome/Firefox/etc.]
- Backend: [localhost:3001]
- Date/Time: [When did it occur?]
```

---

**Happy Testing! 🚀**

