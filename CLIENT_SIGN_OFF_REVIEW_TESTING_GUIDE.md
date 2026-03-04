# 🧪 Client Sign-Off Review Feature - Step-by-Step Testing Guide

## 📋 Overview

This guide will walk you through testing the **Client Sign-Off Review** feature. This feature allows a client to securely review a sprint's performance report and either:
- ✅ **Approve** the deliverable (accept the work)
- ❌ **Request Changes** (ask for modifications before approval)

---

## 🎯 What You'll Need

Before starting, make sure you have:

1. **Three user accounts** (or create them):
   - **Delivery Lead** account (e.g., `deliverylead@example.com`)
   - **Developer** account (e.g., `developer@example.com`)
   - **Client Reviewer** account (e.g., `client@example.com`)

2. **Backend server running** on `http://localhost:3001`

3. **Flutter app running** in your browser

---

## 📝 Step-by-Step Testing Guide

### **PART 1: Setup - Create Project and Sprint** (5 minutes)

#### Step 1.1: Login as Delivery Lead

1. Open your browser and go to the app (usually `http://localhost:XXXXX` where XXXXX is the port shown in your terminal)
2. If you see a login screen, enter your **Delivery Lead** credentials:
   - **Email**: `deliverylead@example.com` (or your Delivery Lead email)
   - **Password**: Your password
3. Click **"Login"** or press Enter
4. **✅ Expected Result**: You should see the dashboard with your name displayed

---

#### Step 1.2: Create a Project

1. Look at the **left sidebar** (dark gray panel on the left)
2. Scroll down in the sidebar to find **"Project Workspace"** (it has a work/home icon)
   - **Note**: If you don't see "Project Workspace", you may need to scroll down in the sidebar
   - It's usually located below "Settings" and "Profile"
3. Click on **"Project Workspace"**
4. You should see a form titled **"Create New Project"** with several sections

5. **Fill in the "Basic Information" section** (first section at the top):
   - **Project Name*** (required): Type `Test Project - Client Review`
   - **Description*** (required): Type `Testing the client sign-off review feature`
   - **Client Name** (optional): Type `Khonology` (or any client name)
   - **Project Owner*** (required): 
     - Click the dropdown arrow on the right side of the "Project Owner" field
     - Select your own name from the list (you should see your Delivery Lead account name)
     - **Important**: You must select a project owner or the form won't save

6. **Fill in the "Project Metadata" section** (scroll down to see this section):
   - **Status**: Click the dropdown and select **"planning"** (should be default)
   - **Priority**: Click the dropdown and select **"medium"** (should be default)
   - **Project Type**: Click the dropdown and select **"Software"** (should be default)
   - **Tags** (optional): You can leave this empty, or type tags like `test, client-review, sprint`

7. **Fill in the "Project Dates" section** (scroll down further):
   - **Start Date**: 
     - Click on the "Start Date" row (it will open a calendar)
     - Select **today's date** from the calendar
     - Click "OK" or "Select" to confirm
   - **End Date**: 
     - Click on the "End Date" row (it will open a calendar)
     - Select a date **3 months from today** (e.g., if today is Feb 20, 2026, select May 20, 2026)
     - Click "OK" or "Select" to confirm

8. **"Team Members" section** (optional - you can skip this for now):
   - You can click "Assign Members" to add team members, but it's not required
   - For testing, you can leave this empty

9. **"Linked Deliverables" section** (optional - skip for now):
   - This will be empty since you haven't created deliverables yet
   - You can skip this section

10. **"Associated Sprints" section** (optional - skip for now):
    - This will be empty since you haven't created sprints yet
    - You can skip this section

11. **Save the project**:
    - Scroll all the way to the bottom of the form
    - You should see two buttons: **"Cancel"** (gray) and **"Create Project"** (red)
    - Click the red **"Create Project"** button

12. **✅ Expected Result**: 
    - You should see a success message (green banner or notification saying "Project created successfully")
    - You should be automatically redirected to the Projects list page or Dashboard
    - Your new project "Test Project - Client Review" should appear in the list
    - If you don't see it immediately, try refreshing the page or navigating to the Projects page

---

#### Step 1.3: Create a Sprint

1. Look in the **left sidebar** and click on **"Sprints"** (or find the **"🏃 Sprint Console"** button)
2. You should see the **Sprint Console** page
3. Look for a **"Create Sprint"** button (usually a red button with a "+" icon or text "Create Sprint")
4. Click **"Create Sprint"** to open the sprint creation form
5. **Fill in the sprint form:**
   - **Project*** (required): 
     - You should see a **"Project"** dropdown field at the top of the form
     - Click the dropdown arrow
     - Select your project: **"Test Project - Client Review"** (the one you just created)
     - **Note**: If you don't see the Project dropdown, it means a project was pre-selected. That's okay, continue with the other fields.
   - **Sprint Name*** (required): Type `Sprint 1 - Client Review Test`
   - **Description**: Type `Sprint for testing client review feature`
   - **Start Date*** (required): 
     - Click on the "Start Date" field
     - Select **today's date** from the calendar
   - **End Date*** (required): 
     - Click on the "End Date" field
     - Select a date **2 weeks from today** (e.g., if today is Feb 20, select March 6)
   - **Planned Points**: Enter `20` (or any number)
6. Scroll down to the bottom of the form
7. Click the **"Create Sprint"** button (usually a red/purple button)
8. **✅ Expected Result**: 
   - You should see a success message (green banner or notification)
   - The sprint should appear in the Sprint Console
   - You can see the sprint in the list
7. **✅ Expected Result**: 
   - Success message appears
   - Sprint appears in the sprint list
   - You can see the sprint details

---

### **PART 2: Create Deliverable** (10 minutes)

#### Step 2.1: Login as Developer

1. **Logout** from the Delivery Lead account:
   - Look for a **"Logout"** button (usually at the bottom of the sidebar or top right)
   - Click it
   - Confirm if asked
2. You should be back at the login screen
3. Now login as **Developer**:
   - **Email**: `developer@example.com` (or your Developer email)
   - **Password**: Your password
4. Click **"Login"**
5. **✅ Expected Result**: Dashboard loads with Developer view

---

#### Step 2.2: Create a Deliverable

1. Look in the **left sidebar** for **"Deliverables"** or find a button to create a deliverable
2. Click **"Create Deliverable"** or **"Enhanced Deliverable Setup"** (or look for a **"+"** button)
3. You should see a form with multiple sections. Fill them out:

   **Basic Information:**
   - **Title**: `API Integration Module`
   - **Description**: `Complete REST API integration with error handling and documentation`
   - **Project**: Select your project from the dropdown ("Test Project - Client Review")
   - **Priority**: Select **"High"** from the dropdown
   - **Due Date**: Select a date **1 month from today**

   **Link Sprint:**
   - Scroll down to find **"Contributing Sprints"** or **"Linked Sprints"** section
   - Click **"Select Sprints"** or **"Add Sprint"**
   - Select the sprint you created earlier: **"Sprint 1 - Client Review Test"**
   - Click **"Add"** or **"Select"**

   **Definition of Done (DoD):**
   - Scroll to **"Definition of Done"** section
   - Click **"Add Item"** or **"+"** button
   - Add these items one by one:
     - `Code reviewed and approved by team lead`
     - `Unit tests written with >80% coverage`
     - `Integration tests pass`
     - `API documentation updated`
     - `Error handling implemented`

   **Evidence Links (Optional but Recommended):**
   - Scroll to **"Evidence"** section
   - Click **"Add Evidence Link"**
   - Fill in:
     - **Type**: Select **"Repository"** from dropdown
     - **URL**: `https://github.com/company/api-integration`
     - **Description**: `Main repository`
   - Click **"Add"** or **"Save"**

   **Upload Files (Important Test):**
   - Scroll to **"Attachments"** or **"Files"** section
   - Click **"Add Document"** or **"Upload File"** button
   - Select any file from your computer (PDF, image, text file - anything)
   - **✅ Expected**: File should upload without errors (no "path unavailable" error)
   - The file name should appear in the attachments list

4. Scroll to the bottom of the form
5. Click **"Create Deliverable"** or **"Submit"** button
6. **✅ Expected Result**: 
   - Success message appears
   - You are redirected to the deliverable detail page
   - All information you entered is visible

---

### **PART 3: Create Sign-Off Report** (5 minutes)

#### Step 3.1: Login as Delivery Lead Again

1. **Logout** from Developer account
2. **Login** as **Delivery Lead** again (same credentials as Step 1.1)

---

#### Step 3.2: Find the Deliverable

1. Navigate to **"Deliverables"** from the sidebar
2. Find the deliverable you just created: **"API Integration Module"**
3. Click on it to open the detail page

---

#### Step 3.3: Create Sign-Off Report

1. On the deliverable detail page, look for a button that says:
   - **"Create Sign-Off Report"** OR
   - **"Generate Report"** OR
   - **"Create Report"**
2. Click it
3. You should see a report creation form or page
4. Fill in the report details:
   - **Executive Summary**: `Payment gateway integration completed with full test coverage`
   - **Technical Details**: `Stripe API v3 integrated, webhook handlers implemented`
   - **Testing**: `Unit tests: 85% coverage, Integration tests: All passing`
   - **Security**: `PCI-DSS compliant token handling`
   - Fill in any other required fields
5. Click **"Create Report"** or **"Save"**
6. **✅ Expected Result**: 
   - Report is created
   - You see the report detail page
   - Report status shows as **"draft"** or **"pending"**

---

#### Step 3.4: Generate Client Review Link

1. On the sign-off report page, look for a button that says:
   - **"Generate Review Link"** OR
   - **"Share with Client"** OR
   - **"Create Review Link"**
2. Click it
3. A form or dialog should appear asking for:
   - **Client Email**: Enter `client@example.com` (or your Client Reviewer email)
   - **Expiration**: Set to **7 days** (or use default)
   - **Single Use** (optional): Leave unchecked or check if you want one-time use
4. Click **"Generate"** or **"Create Link"**
5. **✅ Expected Result**: 
   - A review link is generated and displayed
   - The link looks like: `http://localhost:XXXXX/client-review-token/abc123xyz...`
   - **📋 IMPORTANT**: **Copy this link** - you'll need it in the next part!
   - You should see an expiration date

---

#### Step 3.5: Submit for Review

1. On the report page, look for a button that says:
   - **"Submit for Review"** OR
   - **"Send to Client"**
2. Click it
3. **✅ Expected Result**: 
   - Success message appears
   - Report status changes to **"pending_review"**
   - Deliverable status updates
   - Notification sent to client (if notifications are working)

---

### **PART 4: Client Review - Authenticated Access** (10 minutes)

#### Step 4.1: Login as Client Reviewer

1. **Logout** from Delivery Lead account
2. **Login** as **Client Reviewer**:
   - **Email**: `client@example.com` (or your Client Reviewer email)
   - **Password**: Your password
3. Click **"Login"**
4. **✅ Expected Result**: Dashboard loads

---

#### Step 4.2: View Approval Requests

1. Look in the **left sidebar** for **"Approval Requests"** (or **"Approvals"**)
2. Click it
3. **✅ Expected Result**: 
   - You should see a list of pending approval requests
   - Your deliverable **"API Integration Module"** should appear in the list
   - You can see the report details

---

#### Step 4.3: Open the Report for Review

1. Click on the report or deliverable in the approval requests list
2. You should be taken to a review page
3. **✅ Expected Result**: 
   - Report content is displayed
   - You can see:
     - Executive summary
     - Technical details
     - Testing information
     - Performance visuals (charts/graphs) - if sprint data exists
   - You see two buttons:
     - **"Approve"** button (usually green)
     - **"Request Changes"** button (usually red/orange)

---

#### Step 4.4: Test "Request Changes" Flow

1. Click the **"Request Changes"** button
2. A form or dialog should appear asking for a comment
3. **Test Validation** (Important):
   - Try to submit **WITHOUT** entering a comment
   - Click **"Submit"** or **"Send"**
   - **✅ Expected Result**: 
     - You should see an error message
     - Error says something like: **"Comment is required"** or **"Change request details are mandatory"**
     - The form highlights the comment field
     - Submission is blocked
4. Now enter a comment:
   - In the comment field, type: `Please provide detailed documentation for error handling scenarios, especially for network failures and API timeouts. Also add examples of retry logic implementation.`
5. Click **"Submit"** or **"Send"**
6. **✅ Expected Result**: 
   - Success message appears
   - Message says: **"Changes requested successfully"** or similar
   - Report status changes to **"change_requested"**
   - Deliverable status updates to **"change_requested"**
   - Team members receive notifications (if notifications are working)

---

#### Step 4.5: Verify Change Request (Optional)

1. **Logout** from Client Reviewer
2. **Login** as **Developer** again
3. Go to **"Notifications"** in the sidebar
4. **✅ Expected Result**: 
   - You should see a notification about the change request
   - Click on it to see details
5. Go to the deliverable detail page
6. **✅ Expected Result**: 
   - Status shows **"Change Requested"**
   - You can see the change request comment
   - You can edit the deliverable to address the feedback

---

### **PART 5: Client Review - Token-Based Access (No Login Required)** (10 minutes)

This is the **most important part** - testing that clients can review without logging into the app!

#### Step 5.1: Get the Review Link

1. **Login** as **Delivery Lead** again
2. Go to the sign-off report you created earlier
3. If you don't have the link anymore, generate a new one (Step 3.4)
4. **Copy the review link** (it should look like: `http://localhost:XXXXX/client-review-token/abc123xyz...`)

---

#### Step 5.2: Open Incognito/Private Browser Window

1. **Open a new incognito/private browser window**:
   - **Chrome**: Press `Ctrl + Shift + N` (Windows) or `Cmd + Shift + N` (Mac)
   - **Edge**: Press `Ctrl + Shift + P` (Windows) or `Cmd + Shift + P` (Mac)
   - **Firefox**: Press `Ctrl + Shift + P` (Windows) or `Cmd + Shift + P` (Mac)
2. This simulates a client who is **not logged into the app**

---

#### Step 5.3: Access Review Link (No Login Required)

1. In the incognito window, **paste the review link** you copied into the address bar
2. Press **Enter** to navigate
3. **✅ Expected Result**: 
   - The page loads **WITHOUT** asking you to login
   - No login screen appears
   - You see the sign-off report content directly
   - The report displays:
     - All report sections (summary, technical details, etc.)
     - Performance visuals (charts showing velocity, burndown, etc.)
     - Deliverable information
   - You see the same two buttons:
     - **"Approve"** button
     - **"Request Changes"** button

---

#### Step 5.4: Test Approve via Token (No Login)

1. On the review page (still in incognito window), click the **"Approve"** button
2. A form or dialog should appear
3. **Optional**: Add a comment:
   - Type: `All requested changes have been addressed. Documentation is comprehensive. Approved for production deployment.`
4. **Optional**: Provide digital signature (if prompted)
5. Click **"Submit"** or **"Approve"**
6. **✅ Expected Result**: 
   - Success message appears
   - Message says: **"Report approved successfully"** or similar
   - Report status: **"approved"**
   - Deliverable status: **"approved"**
   - Timestamp is recorded
   - **This works WITHOUT being logged in!**

---

#### Step 5.5: Verify Approval

1. **Close the incognito window**
2. **Login** as **Delivery Lead** (in your regular browser)
3. Go to the deliverable detail page
4. **✅ Expected Result**: 
   - Status shows **"Approved"**
   - You can see:
     - Approval timestamp
     - Who approved it (Client Reviewer name/email)
     - Approval comment (if provided)

---

### **PART 6: Test Error Scenarios** (5 minutes)

#### Step 6.1: Test Expired Token

1. Generate a new review link with **very short expiration** (1 minute)
2. Wait 2 minutes
3. Try to access the link
4. **✅ Expected Result**: 
   - Error message appears
   - Message says: **"Token expired"** or **"Link has expired"**
   - You cannot access the report

---

#### Step 6.2: Test Invalid Token

1. Take a review link and modify it (add/remove characters)
2. Try to access the modified link
3. **✅ Expected Result**: 
   - Error message appears
   - Message says: **"Invalid token"** or **"Link not found"**
   - You cannot access the report

---

## ✅ Success Checklist

After completing all steps, verify:

- [ ] ✅ Project created successfully
- [ ] ✅ Sprint created and linked to project
- [ ] ✅ Deliverable created with all information
- [ ] ✅ File upload works (no "path unavailable" error)
- [ ] ✅ Sign-off report created
- [ ] ✅ Review link generated successfully
- [ ] ✅ Client can access report via link **WITHOUT logging in**
- [ ] ✅ "Request Changes" works with mandatory comment validation
- [ ] ✅ "Approve" works via token (no login required)
- [ ] ✅ Statuses update correctly (pending → change_requested → approved)
- [ ] ✅ Notifications sent to team members
- [ ] ✅ Expired tokens are rejected
- [ ] ✅ Invalid tokens are rejected

---

## 🐛 Troubleshooting

### Problem: Can't find "Create Sign-Off Report" button

**Solution**: 
- Make sure you're logged in as **Delivery Lead**
- Check that the deliverable is in the correct status
- Look for alternative button names: "Generate Report", "Create Report"

---

### Problem: Review link doesn't work

**Solution**:
- Check that the link was copied completely (no truncation)
- Verify the Flutter app is still running
- Make sure the token hasn't expired
- Try generating a new link

---

### Problem: "Request Changes" allows submission without comment

**Solution**:
- This is a bug - the validation should prevent this
- Check browser console (F12) for errors
- Verify backend is running and receiving the request

---

### Problem: Performance visuals don't show

**Solution**:
- This is normal if the sprint doesn't have enough data
- The charts need sprint metrics (velocity, burndown data)
- Try adding some sprint progress data first

---

### Problem: Can't see notifications

**Solution**:
- Check that notifications are enabled in the app
- Verify the notification service is working
- Check backend logs for notification errors

---

## 📊 What to Document

As you test, note:

1. **Which steps worked perfectly** ✅
2. **Which steps had issues** ❌
3. **Error messages** (copy exact text)
4. **Screenshots** of any problems
5. **Browser console errors** (F12 → Console tab)
6. **Backend terminal errors** (check server logs)

---

## 🎉 Congratulations!

If you completed all steps successfully, you've fully tested the **Client Sign-Off Review** feature! This feature enables:

- ✅ Secure client review without requiring app login
- ✅ Formal approval process with audit trail
- ✅ Change request workflow with mandatory feedback
- ✅ Token-based access with expiration
- ✅ Integration with sprint performance data

---

## 📞 Need Help?

If you encounter issues:
1. Check the **Troubleshooting** section above
2. Review browser console (F12) for errors
3. Check backend terminal for server errors
4. Verify all services are running (backend on port 3001, Flutter app)

---

**Happy Testing! 🚀**

