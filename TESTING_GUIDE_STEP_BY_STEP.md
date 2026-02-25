# Complete Testing Guide - Step by Step

## 🚀 Prerequisites

1. **Backend Server**: Running on `http://localhost:3001`
2. **Flutter App**: Running in Chrome browser
3. **Database**: All tables created (run `node migrations/ensure_missing_tables_fullscan.cjs` if needed)

---

## 📋 Testing Order (Follow This Sequence)

### **Phase 1: Authentication & Basic Setup** ✅

#### Step 1.1: Login
1. Open the app in Chrome (should auto-open)
2. If not logged in, enter your credentials
3. **Expected**: Successfully logged in, redirected to Dashboard
4. **Verify**: Your name/email appears in the top-right corner

---

### **Phase 2: Project Management** 📁

#### Step 2.1: Create a Project (if needed)
1. Navigate to **Dashboard** or **Projects** section
2. Click **"Create Project"** or **"+"** button
3. Fill in:
   - **Name**: "Test Project 2026"
   - **Description**: "Testing sprint and deliverable creation"
4. Click **"Create"** or **"Save"**
5. **Expected**: Project created successfully
6. **Verify**: Project appears in your projects list
7. **Note**: Copy/remember the Project ID (you'll need it)

---

### **Phase 3: Sprint Creation** 🏃‍♂️

#### Step 3.1: Create a Sprint (via Sprints Page)
1. Click **"Sprints"** in the left sidebar
2. Click **"Create Sprint"** or **"+"** button
3. Fill in the form:
   - **Name**: "Sprint 1 - February 2026"
   - **Start Date**: Select today's date
   - **End Date**: Select a date 2 weeks from today
   - **Project**: Select your test project (if dropdown available)
   - **Description**: "Test sprint for deliverable creation"
4. Click **"Create"** or **"Save"**
5. **Expected**: 
   - ✅ Success message: "Sprint created successfully"
   - ✅ Sprint appears in sprints list
   - ✅ No error messages
6. **Verify**: 
   - Sprint shows in the list with correct name and dates
   - Status is "planning" or "draft"
   - You can click on it to view details

#### Step 3.2: Verify Sprint in Database (Optional)
- Open browser DevTools (F12) → Console
- Check for any errors
- Sprint should be saved with all fields

---

### **Phase 4: Deliverable Creation** 📦

#### Step 4.1: Navigate to Deliverable Setup
1. Click **"Deliverables"** in sidebar (or navigate to deliverable section)
2. Click **"Create Deliverable"** or **"+"** button
3. You should see the **"Enhanced Deliverable Setup Screen"**

#### Step 4.2: Fill Basic Deliverable Information
1. **Title**: "Test Deliverable - API Integration"
2. **Description**: "Testing deliverable creation with file uploads"
3. **Project**: Select your test project
4. **Priority**: Select "High" or "Medium"
5. **Due Date**: Select a date in the future

#### Step 4.3: Link Sprint(s)
1. Scroll to **"Contributing Sprints"** section
2. Click **"Select Sprints"** dropdown
3. Select the sprint you created in Step 3.1
4. **Expected**: Sprint appears as selected (1 selected)

#### Step 4.4: Add Definition of Done (DoD) Items
1. Scroll to **"Definition of Done"** section
2. Click **"Add Item"** or **"+"**
3. Add items like:
   - "Code reviewed and approved"
   - "Unit tests written and passing"
   - "Documentation updated"
4. **Expected**: Items appear in the list

#### Step 4.5: Add Evidence Links
1. Scroll to **"Evidence"** section
2. Click **"Add Evidence Link"**
3. Add a test link:
   - **Type**: "Repository"
   - **URL**: "https://github.com/test/repo"
   - **Description**: "Main repository"
4. **Expected**: Link appears in the list

#### Step 4.6: Upload Files (Test Web File Picker Fix)
1. Scroll to **"Attachments"** or **"Files"** section
2. Click **"Add Document"** or **"Upload File"**
3. Select a file from your computer (any file - PDF, image, etc.)
4. **Expected**: 
   - ✅ File picker opens
   - ✅ File is selected without errors
   - ✅ File appears in the attachments list
   - ✅ **NO ERROR** about "path is unavailable"
5. **Verify**: File name appears in the list

#### Step 4.7: Review AI Readiness Gate
1. Scroll to **"AI Release Readiness Gate"** section
2. **Expected**: 
   - Status card shows (Green/Amber/Red)
   - Recommendations appear if any
   - You can proceed or request internal approval

#### Step 4.8: Submit Deliverable
1. Scroll to bottom of the form
2. Click **"Create Deliverable"** or **"Submit"**
3. **Expected**: 
   - ✅ Success message: "Deliverable created successfully"
   - ✅ Redirected to deliverable detail page or list
   - ✅ **NO ERROR** about file path
4. **Verify**: 
   - Deliverable appears in deliverables list
   - All information is saved correctly
   - Linked sprint shows in deliverable details

---

### **Phase 5: Verify Data Persistence** 💾

#### Step 5.1: Refresh the Page
1. Press **F5** or click refresh button
2. **Expected**: All data still present (no data loss)

#### Step 5.2: View Sprint Details
1. Go to **Sprints** page
2. Click on the sprint you created
3. **Expected**: 
   - Sprint details load correctly
   - Linked deliverable appears (if shown)
   - Dates and information are correct

#### Step 5.3: View Deliverable Details
1. Go to **Deliverables** page
2. Click on the deliverable you created
3. **Expected**: 
   - All information displays correctly
   - Linked sprint shows
   - Files/attachments are accessible
   - Evidence links work

---

### **Phase 6: Client Sign-Off Review Feature** ✅

#### Step 6.1: Create a Sign-Off Report
1. Navigate to the deliverable you created
2. Look for **"Create Sign-Off Report"** or **"Generate Report"** button
3. Fill in report details if prompted
4. Click **"Create"** or **"Submit"**
5. **Expected**: Report created successfully

#### Step 6.2: Generate Client Review Link
1. On the sign-off report page, look for **"Generate Review Link"** or **"Share with Client"**
2. Enter a client email: `client@example.com`
3. Set expiration (default 7 days is fine)
4. Click **"Generate Link"**
5. **Expected**: 
   - ✅ Token/link generated
   - ✅ Link displayed (copy it)
   - ✅ Expiration date shown

#### Step 6.3: Test Token-Based Access (Client View)
1. **Open a new incognito/private browser window** (to simulate unauthenticated client)
2. Paste the review link in the address bar
3. Navigate to: `http://localhost:<port>/client-review-token/<your-token>`
4. **Expected**: 
   - ✅ Page loads WITHOUT requiring login
   - ✅ Sign-off report content displays
   - ✅ Performance visuals render (if sprint data exists)
   - ✅ "Approve" and "Request Changes" buttons visible

#### Step 6.4: Test Approve Flow
1. On the client review page, click **"Approve"**
2. **Optional**: Add a comment: "Looks good, approved"
3. **Optional**: Provide digital signature (if prompted)
4. Click **"Submit"** or **"Approve"**
5. **Expected**: 
   - ✅ Success message
   - ✅ Report status updates to "Approved"
   - ✅ Deliverable status updates to "Approved"
   - ✅ Timestamp recorded

#### Step 6.5: Test Request Changes Flow
1. **Create another sign-off report** (or reset the first one)
2. Generate a new review link
3. Access it in incognito window
4. Click **"Request Changes"**
5. **Try submitting WITHOUT comment** (should fail validation)
6. **Expected**: 
   - ✅ Error message: "Comment is required"
   - ✅ Form highlights the comment field
7. **Add mandatory comment**: "Please update the velocity calculations"
8. Click **"Submit"**
9. **Expected**: 
   - ✅ Success message
   - ✅ Report status updates to "Change Requested"
   - ✅ Deliverable status updates to "Change Requested"
   - ✅ Team members receive notifications

---

### **Phase 7: Error Scenarios** ⚠️

#### Step 7.1: Test Expired Token
1. Generate a review link with short expiration (10 seconds)
2. Wait 15 seconds
3. Try to access the link
4. **Expected**: Error message about expired token

#### Step 7.2: Test Invalid Token
1. Navigate to: `http://localhost:<port>/client-review-token/invalid-token-12345`
2. **Expected**: Error message about invalid token

#### Step 7.3: Test Sprint Creation Without Required Fields
1. Try to create a sprint without name
2. **Expected**: Validation error prevents submission

#### Step 7.4: Test Deliverable Creation Without Project
1. Try to create a deliverable without selecting a project
2. **Expected**: Validation error or project selection required

---

## ✅ Success Criteria Checklist

### Sprint Creation
- [ ] Sprint creates successfully
- [ ] All fields save correctly
- [ ] Sprint appears in list
- [ ] Sprint can be edited
- [ ] Sprint links to project correctly

### Deliverable Creation
- [ ] Deliverable creates successfully
- [ ] All fields save correctly
- [ ] File upload works on web (no path error)
- [ ] Sprint linking works
- [ ] Evidence links save
- [ ] DoD items save
- [ ] Deliverable appears in list

### Client Review Feature
- [ ] Review link generates successfully
- [ ] Token-based access works (no login required)
- [ ] Performance visuals render
- [ ] Approve flow works
- [ ] Request Changes flow works
- [ ] Mandatory comment validation works
- [ ] Notifications sent correctly
- [ ] Audit trail created

---

## 🐛 Troubleshooting

### If Sprint Creation Fails:
1. Check browser console (F12) for errors
2. Check backend logs for SQL errors
3. Verify project exists and you have permission
4. Try creating sprint without project_id first

### If Deliverable Creation Fails:
1. Check browser console for file picker errors
2. Verify you're using the fixed `enhanced_deliverable_setup_screen.dart`
3. Try creating deliverable without file attachments first
4. Check backend logs for validation errors

### If Client Review Link Fails:
1. Verify sign-off report exists
2. Check backend logs for token generation errors
3. Verify database has `sign_off_reports` table
4. Check token format in URL

### If File Upload Fails:
1. Verify you're on web platform (Chrome)
2. Check that `kIsWeb` check is working
3. Verify `file.bytes` is not null
4. Check backend `/files/upload` endpoint exists

---

## 📊 Expected Database State After Testing

After completing all tests, verify in database:

```sql
-- Check sprints
SELECT id, name, project_id, start_date, end_date, status 
FROM sprints 
ORDER BY created_at DESC LIMIT 5;

-- Check deliverables
SELECT id, title, project_id, status, created_at 
FROM deliverables 
ORDER BY created_at DESC LIMIT 5;

-- Check sprint-deliverable links
SELECT * FROM sprint_deliverables 
ORDER BY created_at DESC LIMIT 5;

-- Check sign-off reports
SELECT id, deliverable_id, status, created_at 
FROM sign_off_reports 
ORDER BY created_at DESC LIMIT 5;
```

---

## 🎯 Quick Test Summary

**Minimum Viable Test (5 minutes):**
1. ✅ Login
2. ✅ Create 1 sprint
3. ✅ Create 1 deliverable (with file upload)
4. ✅ Verify both appear in lists

**Full Test (15-20 minutes):**
- Complete all phases above
- Test all error scenarios
- Verify all features work end-to-end

---

## 📝 Notes

- **Backend URL**: `http://localhost:3001`
- **Frontend URL**: `http://localhost:<port>` (check browser address bar)
- **Database**: PostgreSQL on `localhost:5432`
- **Logs**: Check browser console (F12) and backend terminal

---

## 🆘 Need Help?

If you encounter any errors:
1. **Copy the exact error message**
2. **Note which step you were on**
3. **Check browser console (F12)**
4. **Check backend terminal logs**
5. Share all of this information for debugging

---

**Happy Testing! 🚀**

