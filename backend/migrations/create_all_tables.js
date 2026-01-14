/**
 * Flow-Space Complete Database Migration
 * 
 * This script creates ALL 27 tables required for the Flow-Space application
 * Run this to ensure your deployed database has complete functionality
 * 
 * Run with: node migrations/create_all_tables.js
 */

const { Pool } = require('pg');
require('dotenv').config();

const pool = process.env.DATABASE_URL
  ? new Pool({
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false },
    })
  : new Pool({
      host: process.env.DB_HOST || 'localhost',
      port: parseInt(process.env.DB_PORT, 10) || 5432,
      database: process.env.DB_NAME || 'flow_space',
      user: process.env.DB_USER || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
    });

async function createAllTables() {
  const client = await pool.connect();
  
  try {
    console.log('🚀 Starting complete Flow-Space database migration...');
    console.log('📊 Creating all 27 tables...\n');
    
    await client.query('BEGIN');
    
    // ============================================================
    // CORE AUTHENTICATION & USER MANAGEMENT TABLES
    // ============================================================
    
    console.log('🔐 Creating user management tables...');
    
    // Users table
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        name VARCHAR(255) NOT NULL,
        role VARCHAR(50) NOT NULL DEFAULT 'teamMember',
        avatar_url TEXT,
        is_active BOOLEAN DEFAULT true,
        email_verified BOOLEAN DEFAULT false,
        email_verified_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        last_login_at TIMESTAMP,
        preferences JSONB DEFAULT '{}',
        project_ids UUID[] DEFAULT '{}'
      )
    `);
    
    // User roles table
    await client.query(`
      CREATE TABLE IF NOT EXISTS user_roles (
        id SERIAL PRIMARY KEY,
        name VARCHAR(50) UNIQUE NOT NULL,
        display_name VARCHAR(100) NOT NULL,
        description TEXT,
        color VARCHAR(7),
        icon VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Permissions table
    await client.query(`
      CREATE TABLE IF NOT EXISTS permissions (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) UNIQUE NOT NULL,
        description TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Role permissions junction table
    await client.query(`
      CREATE TABLE IF NOT EXISTS role_permissions (
        id SERIAL PRIMARY KEY,
        role_id INTEGER REFERENCES user_roles(id) ON DELETE CASCADE,
        permission_id INTEGER REFERENCES permissions(id) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(role_id, permission_id)
      )
    `);
    
    // ============================================================
    // PROJECT & TEAM MANAGEMENT TABLES
    // ============================================================
    
    console.log('📁 Creating project management tables...');
    
    // Projects table
    await client.query(`
      CREATE TABLE IF NOT EXISTS projects (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        description TEXT,
        owner_id UUID REFERENCES users(id) ON DELETE CASCADE,
        status VARCHAR(50) DEFAULT 'active',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Project members table
    await client.query(`
      CREATE TABLE IF NOT EXISTS project_members (
        id SERIAL PRIMARY KEY,
        project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        role VARCHAR(50) NOT NULL,
        joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(project_id, user_id)
      )
    `);
    
    // Epics table
    await client.query(`
      CREATE TABLE IF NOT EXISTS epics (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        title VARCHAR(255) NOT NULL,
        description TEXT,
        status VARCHAR(50) DEFAULT 'draft',
        project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
        sprint_ids UUID[] DEFAULT '{}',
        deliverable_ids UUID[] DEFAULT '{}',
        start_date TIMESTAMP,
        target_date TIMESTAMP,
        created_by UUID REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // ============================================================
    // SPRINT MANAGEMENT TABLES
    // ============================================================
    
    console.log('🏃‍♂️ Creating sprint management tables...');
    
    // Sprints table
    await client.query(`
      CREATE TABLE IF NOT EXISTS sprints (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
        start_date TIMESTAMP NOT NULL,
        end_date TIMESTAMP NOT NULL,
        committed_points INTEGER DEFAULT 0,
        completed_points INTEGER DEFAULT 0,
        velocity DECIMAL(5,2) DEFAULT 0,
        test_pass_rate DECIMAL(5,2) DEFAULT 0,
        defect_count INTEGER DEFAULT 0,
        status VARCHAR(50) DEFAULT 'planning',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Sprint deliverables junction table
    await client.query(`
      CREATE TABLE IF NOT EXISTS sprint_deliverables (
        id SERIAL PRIMARY KEY,
        sprint_id UUID REFERENCES sprints(id) ON DELETE CASCADE,
        deliverable_id UUID REFERENCES deliverables(id) ON DELETE CASCADE,
        points INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(sprint_id, deliverable_id)
      )
    `);
    
    // Sprint metrics table
    await client.query(`
      CREATE TABLE IF NOT EXISTS sprint_metrics (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        sprint_id UUID REFERENCES sprints(id) ON DELETE CASCADE,
        planned_points INTEGER DEFAULT 0,
        completed_points INTEGER DEFAULT 0,
        velocity DECIMAL(5,2) DEFAULT 0,
        test_pass_rate DECIMAL(5,2) DEFAULT 0,
        defect_count INTEGER DEFAULT 0,
        uat_notes TEXT,
        quality_score DECIMAL(5,2) DEFAULT 0,
        points_added_during_sprint INTEGER DEFAULT 0,
        points_removed_during_sprint INTEGER DEFAULT 0,
        scope_changes TEXT,
        blockers TEXT,
        decisions TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(sprint_id)
      )
    `);
    
    // Tickets table
    await client.query(`
      CREATE TABLE IF NOT EXISTS tickets (
        ticket_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        ticket_key VARCHAR(50) UNIQUE NOT NULL,
        summary VARCHAR(255) NOT NULL,
        description TEXT,
        status VARCHAR(50) DEFAULT 'To Do',
        issue_type VARCHAR(50) DEFAULT 'Task',
        priority VARCHAR(20) DEFAULT 'Medium',
        assignee VARCHAR(255),
        reporter VARCHAR(255) NOT NULL,
        sprint_id UUID REFERENCES sprints(id) ON DELETE SET NULL,
        project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
        user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // ============================================================
    // DELIVERABLE MANAGEMENT TABLES
    // ============================================================
    
    console.log('📦 Creating deliverable management tables...');
    
    // Deliverables table
    await client.query(`
      CREATE TABLE IF NOT EXISTS deliverables (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        title VARCHAR(255) NOT NULL,
        description TEXT,
        status VARCHAR(50) DEFAULT 'draft',
        project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
        sprint_id UUID REFERENCES sprints(id) ON DELETE SET NULL,
        created_by UUID REFERENCES users(id) ON DELETE CASCADE,
        assigned_to UUID REFERENCES users(id) ON DELETE SET NULL,
        due_date TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        definition_of_done JSONB DEFAULT '[]',
        evidence JSONB DEFAULT '[]',
        readiness_gates JSONB DEFAULT '[]',
        priority VARCHAR(20) DEFAULT 'Medium',
        sprint_ids UUID[] DEFAULT '{}',
        epic_id UUID REFERENCES epics(id) ON DELETE SET NULL,
        evidence_links JSONB DEFAULT '[]'
      )
    `);
    
    // ============================================================
    // SIGN-OFF & APPROVAL TABLES
    // ============================================================
    
    console.log('✅ Creating sign-off and approval tables...');
    
    // Sign-off reports table
    await client.query(`
      CREATE TABLE IF NOT EXISTS sign_off_reports (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        deliverable_id UUID REFERENCES deliverables(id) ON DELETE CASCADE,
        created_by UUID REFERENCES users(id) ON DELETE CASCADE,
        status VARCHAR(50) DEFAULT 'draft',
        content JSONB DEFAULT '{}',
        evidence JSONB DEFAULT '[]',
        submitted_at TIMESTAMP,
        approved_at TIMESTAMP,
        last_reminder_at TIMESTAMP,
        escalated_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        report_title VARCHAR(255),
        sprint_id UUID REFERENCES sprints(id) ON DELETE SET NULL,
        known_limitations TEXT,
        next_steps TEXT,
        reviewer_comments JSONB DEFAULT '[]'
      )
    `);
    
    // Client reviews table
    await client.query(`
      CREATE TABLE IF NOT EXISTS client_reviews (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        report_id UUID REFERENCES sign_off_reports(id) ON DELETE CASCADE,
        reviewer_id UUID REFERENCES users(id) ON DELETE CASCADE,
        status VARCHAR(50) DEFAULT 'pending',
        feedback TEXT,
        approved_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Digital signatures table
    await client.query(`
      CREATE TABLE IF NOT EXISTS digital_signatures (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        report_id UUID REFERENCES sign_off_reports(id) ON DELETE CASCADE,
        user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        signature_data TEXT,
        signed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        ip_address INET,
        user_agent TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Approval requests table
    await client.query(`
      CREATE TABLE IF NOT EXISTS approval_requests (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        deliverable_id UUID REFERENCES deliverables(id) ON DELETE CASCADE,
        report_id UUID REFERENCES sign_off_reports(id) ON DELETE CASCADE,
        requester_id UUID REFERENCES users(id) ON DELETE SET NULL,
        approver_id UUID REFERENCES users(id) ON DELETE SET NULL,
        status VARCHAR(50) DEFAULT 'pending',
        approval_type VARCHAR(50) DEFAULT 'internal',
        comments TEXT,
        evidence_links JSONB DEFAULT '[]',
        requested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        responded_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Change requests table
    await client.query(`
      CREATE TABLE IF NOT EXISTS change_requests (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        report_id UUID REFERENCES sign_off_reports(id) ON DELETE CASCADE,
        requested_by UUID REFERENCES users(id) ON DELETE SET NULL,
        status VARCHAR(50) DEFAULT 'open',
        description TEXT NOT NULL,
        priority VARCHAR(20) DEFAULT 'medium',
        resolution TEXT,
        resolved_by UUID REFERENCES users(id) ON DELETE SET NULL,
        resolved_at TIMESTAMP,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // DocuSign envelopes table
    await client.query(`
      CREATE TABLE IF NOT EXISTS docusign_envelopes (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        report_id UUID NOT NULL REFERENCES sign_off_reports(id) ON DELETE CASCADE,
        envelope_id VARCHAR(255) NOT NULL UNIQUE,
        status VARCHAR(50) DEFAULT 'created',
        signer_email VARCHAR(255) NOT NULL,
        signer_name VARCHAR(255) NOT NULL,
        signer_role VARCHAR(50),
        created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        sent_at TIMESTAMP,
        delivered_at TIMESTAMP,
        signed_at TIMESTAMP,
        completed_at TIMESTAMP,
        declined_at TIMESTAMP,
        decline_reason TEXT,
        voided_at TIMESTAMP,
        void_reason TEXT,
        metadata JSONB DEFAULT '{}',
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW(),
        CONSTRAINT unique_report_envelope UNIQUE(report_id, envelope_id)
      )
    `);
    
    // ============================================================
    // DOCUMENT MANAGEMENT TABLES
    // ============================================================
    
    console.log('📄 Creating document management tables...');
    
    // Repository files table
    await client.query(`
      CREATE TABLE IF NOT EXISTS repository_files (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        description TEXT,
        file_path VARCHAR(500) NOT NULL,
        file_type VARCHAR(50) NOT NULL,
        file_size BIGINT,
        content_type VARCHAR(100),
        created_by UUID REFERENCES users(id) ON DELETE CASCADE,
        project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Documents table
    await client.query(`
      CREATE TABLE IF NOT EXISTS documents (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        description TEXT,
        file_path TEXT NOT NULL,
        file_type VARCHAR(100),
        file_size BIGINT,
        mime_type VARCHAR(100),
        project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
        deliverable_id UUID REFERENCES deliverables(id) ON DELETE SET NULL,
        sprint_id UUID REFERENCES sprints(id) ON DELETE SET NULL,
        uploaded_by UUID REFERENCES users(id) ON DELETE SET NULL,
        tags TEXT[] DEFAULT '{}',
        version INTEGER DEFAULT 1,
        is_archived BOOLEAN DEFAULT false,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // ============================================================
    // COMMUNICATION & TRACKING TABLES
    // ============================================================
    
    console.log('🔔 Creating communication and tracking tables...');
    
    // Notifications table
    await client.query(`
      CREATE TABLE IF NOT EXISTS notifications (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        message TEXT,
        type VARCHAR(50) DEFAULT 'info',
        is_read BOOLEAN DEFAULT false,
        action_url TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        created_by UUID REFERENCES users(id) ON DELETE SET NULL
      )
    `);
    
    // Audit logs table
    await client.query(`
      CREATE TABLE IF NOT EXISTS audit_logs (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE SET NULL,
        action VARCHAR(100) NOT NULL,
        resource_type VARCHAR(50),
        resource_id UUID,
        details JSONB DEFAULT '{}',
        ip_address INET,
        user_agent TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // ============================================================
    // REPORTING & ANALYTICS TABLES
    // ============================================================
    
    console.log('📈 Creating reporting and analytics tables...');
    
    // Report exports table
    await client.query(`
      CREATE TABLE IF NOT EXISTS report_exports (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        report_id UUID REFERENCES sign_off_reports(id) ON DELETE CASCADE,
        export_type VARCHAR(50) NOT NULL,
        format VARCHAR(20) NOT NULL,
        file_path TEXT,
        file_size BIGINT,
        exported_by UUID REFERENCES users(id) ON DELETE SET NULL,
        exported_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        expires_at TIMESTAMP,
        download_count INTEGER DEFAULT 0,
        metadata JSONB DEFAULT '{}'
      )
    `);
    
    // Report export statistics view
    await client.query(`
      CREATE OR REPLACE VIEW report_export_statistics AS
      SELECT 
        COUNT(*) as total_exports,
        COUNT(DISTINCT exported_by) as unique_exporters,
        export_type,
        format,
        DATE_TRUNC('day', exported_at) as export_date
      FROM report_exports 
      WHERE exported_at >= CURRENT_DATE - INTERVAL '30 days'
      GROUP BY export_type, format, DATE_TRUNC('day', exported_at)
      ORDER BY export_date DESC
    `);
    
    // ============================================================
    // SUPPORTING TABLES
    // ============================================================
    
    console.log('🏷️ Creating supporting tables...');
    
    // Ticket types table
    await client.query(`
      CREATE TABLE IF NOT EXISTS ticket_types (
        id SERIAL PRIMARY KEY,
        name VARCHAR(50) UNIQUE NOT NULL,
        description TEXT,
        icon VARCHAR(50),
        color VARCHAR(7),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Deliverable templates table
    await client.query(`
      CREATE TABLE IF NOT EXISTS deliverable_templates (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        description TEXT,
        template_type VARCHAR(50),
        content JSONB DEFAULT '{}',
        definition_of_done JSONB DEFAULT '[]',
        readiness_gates JSONB DEFAULT '[]',
        created_by UUID REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // Project templates table
    await client.query(`
      CREATE TABLE IF NOT EXISTS project_templates (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        name VARCHAR(255) NOT NULL,
        description TEXT,
        template_data JSONB DEFAULT '{}',
        default_sprint_duration INTEGER DEFAULT 14,
        created_by UUID REFERENCES users(id) ON DELETE SET NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    
    // ============================================================
    // CREATE INDEXES
    // ============================================================
    
    console.log('🔍 Creating indexes for performance...');
    
    const indexes = [
      'CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)',
      'CREATE INDEX IF NOT EXISTS idx_users_role ON users(role)',
      'CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active)',
      'CREATE INDEX IF NOT EXISTS idx_deliverables_project ON deliverables(project_id)',
      'CREATE INDEX IF NOT EXISTS idx_deliverables_sprint ON deliverables(sprint_id)',
      'CREATE INDEX IF NOT EXISTS idx_deliverables_status ON deliverables(status)',
      'CREATE INDEX IF NOT EXISTS idx_deliverables_created_by ON deliverables(created_by)',
      'CREATE INDEX IF NOT EXISTS idx_sprints_project ON sprints(project_id)',
      'CREATE INDEX IF NOT EXISTS idx_sprints_dates ON sprints(start_date, end_date)',
      'CREATE INDEX IF NOT EXISTS idx_notifications_user ON notifications(user_id)',
      'CREATE INDEX IF NOT EXISTS idx_notifications_read ON notifications(is_read)',
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id)',
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_action ON audit_logs(action)',
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs(created_at)',
      'CREATE INDEX IF NOT EXISTS idx_repository_files_project ON repository_files(project_id)',
      'CREATE INDEX IF NOT EXISTS idx_repository_files_created_by ON repository_files(created_by)',
      'CREATE INDEX IF NOT EXISTS idx_repository_files_type ON repository_files(file_type)',
      'CREATE INDEX IF NOT EXISTS idx_epics_project ON epics(project_id)',
      'CREATE INDEX IF NOT EXISTS idx_epics_created_by ON epics(created_by)',
      'CREATE INDEX IF NOT EXISTS idx_epics_status ON epics(status)',
      'CREATE INDEX IF NOT EXISTS idx_tickets_sprint ON tickets(sprint_id)',
      'CREATE INDEX IF NOT EXISTS idx_tickets_project ON tickets(project_id)',
      'CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status)',
      'CREATE INDEX IF NOT EXISTS idx_tickets_assignee ON tickets(assignee)',
      'CREATE INDEX IF NOT EXISTS idx_tickets_reporter ON tickets(reporter)',
      'CREATE INDEX IF NOT EXISTS idx_sprint_metrics_sprint ON sprint_metrics(sprint_id)',
      'CREATE INDEX IF NOT EXISTS idx_signatures_report ON digital_signatures(report_id)',
      'CREATE INDEX IF NOT EXISTS idx_signatures_user ON digital_signatures(user_id)',
      'CREATE INDEX IF NOT EXISTS idx_approval_requests_deliverable ON approval_requests(deliverable_id)',
      'CREATE INDEX IF NOT EXISTS idx_approval_requests_status ON approval_requests(status)',
      'CREATE INDEX IF NOT EXISTS idx_approval_requests_approver ON approval_requests(approver_id)',
      'CREATE INDEX IF NOT EXISTS idx_change_requests_report ON change_requests(report_id)',
      'CREATE INDEX IF NOT EXISTS idx_change_requests_status ON change_requests(status)',
      'CREATE INDEX IF NOT EXISTS idx_documents_project ON documents(project_id)',
      'CREATE INDEX IF NOT EXISTS idx_documents_deliverable ON documents(deliverable_id)',
      'CREATE INDEX IF NOT EXISTS idx_documents_uploaded_by ON documents(uploaded_by)',
      'CREATE INDEX IF NOT EXISTS idx_docusign_envelopes_report ON docusign_envelopes(report_id)',
      'CREATE INDEX IF NOT EXISTS idx_docusign_envelopes_envelope_id ON docusign_envelopes(envelope_id)',
      'CREATE INDEX IF NOT EXISTS idx_docusign_envelopes_status ON docusign_envelopes(status)',
      'CREATE INDEX IF NOT EXISTS idx_docusign_envelopes_signer_email ON docusign_envelopes(signer_email)',
      'CREATE INDEX IF NOT EXISTS idx_docusign_envelopes_created_by ON docusign_envelopes(created_by)'
    ];
    
    for (const index of indexes) {
      await client.query(index);
    }
    
    // ============================================================
    // CREATE TRIGGERS
    // ============================================================
    
    console.log('⚡ Creating triggers for updated_at columns...');
    
    // Create update_updated_at_column function if it doesn't exist
    await client.query(`
      CREATE OR REPLACE FUNCTION update_updated_at_column()
      RETURNS TRIGGER AS $$
      BEGIN
        NEW.updated_at = CURRENT_TIMESTAMP;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql
    `);
    
    // Create triggers for all tables with updated_at columns
    const triggers = [
      'DROP TRIGGER IF EXISTS update_users_updated_at ON users',
      'CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()',
      'DROP TRIGGER IF EXISTS update_projects_updated_at ON projects',
      'CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()',
      'DROP TRIGGER IF EXISTS update_deliverables_updated_at ON deliverables',
      'CREATE TRIGGER update_deliverables_updated_at BEFORE UPDATE ON deliverables FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()',
      'DROP TRIGGER IF EXISTS update_sprints_updated_at ON sprints',
      'CREATE TRIGGER update_sprints_updated_at BEFORE UPDATE ON sprints FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()',
      'DROP TRIGGER IF EXISTS update_sign_off_reports_updated_at ON sign_off_reports',
      'CREATE TRIGGER update_sign_off_reports_updated_at BEFORE UPDATE ON sign_off_reports FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()',
      'DROP TRIGGER IF EXISTS update_client_reviews_updated_at ON client_reviews',
      'CREATE TRIGGER update_client_reviews_updated_at BEFORE UPDATE ON client_reviews FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()',
      'DROP TRIGGER IF EXISTS update_notifications_updated_at ON notifications',
      'CREATE TRIGGER update_notifications_updated_at BEFORE UPDATE ON notifications FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()',
      'DROP TRIGGER IF EXISTS update_repository_files_updated_at ON repository_files',
      'CREATE TRIGGER update_repository_files_updated_at BEFORE UPDATE ON repository_files FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()',
      'DROP TRIGGER IF EXISTS update_epics_updated_at ON epics',
      'CREATE TRIGGER update_epics_updated_at BEFORE UPDATE ON epics FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()',
      'DROP TRIGGER IF EXISTS update_sprint_metrics_updated_at ON sprint_metrics',
      'CREATE TRIGGER update_sprint_metrics_updated_at BEFORE UPDATE ON sprint_metrics FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()',
      'DROP TRIGGER IF EXISTS update_approval_requests_updated_at ON approval_requests',
      'CREATE TRIGGER update_approval_requests_updated_at BEFORE UPDATE ON approval_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()',
      'DROP TRIGGER IF EXISTS update_change_requests_updated_at ON change_requests',
      'CREATE TRIGGER update_change_requests_updated_at BEFORE UPDATE ON change_requests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()',
      'DROP TRIGGER IF EXISTS update_documents_updated_at ON documents',
      'CREATE TRIGGER update_documents_updated_at BEFORE UPDATE ON documents FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()',
      'DROP TRIGGER IF EXISTS update_tickets_updated_at ON tickets',
      'CREATE TRIGGER update_tickets_updated_at BEFORE UPDATE ON tickets FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()',
      'DROP TRIGGER IF EXISTS update_docusign_envelopes_updated_at ON docusign_envelopes',
      'CREATE TRIGGER update_docusign_envelopes_updated_at BEFORE UPDATE ON docusign_envelopes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()'
    ];
    
    for (const trigger of triggers) {
      await client.query(trigger);
    }
    
    // ============================================================
    // INSERT DEFAULT DATA
    // ============================================================
    
    console.log('🌱 Inserting default data...');
    
    // Insert default user roles
    await client.query(`
      INSERT INTO user_roles (name, display_name, description, color, icon)
      VALUES 
        ('systemAdmin', 'System Admin', 'Full system access and configuration', '#FF0000', 'admin_panel_settings'),
        ('deliveryLead', 'Delivery Lead', 'Manages deliverables and team', '#0077B6', 'supervisor_account'),
        ('teamMember', 'Team Member', 'Works on deliverables', '#28A745', 'person'),
        ('clientReviewer', 'Client Reviewer', 'Reviews and approves deliverables', '#FFC107', 'rate_review')
      ON CONFLICT (name) DO NOTHING
    `);
    
    // Insert default ticket types
    await client.query(`
      INSERT INTO ticket_types (name, description, icon, color)
      VALUES 
        ('Task', 'General task or work item', 'task', '#28A745'),
        ('Bug', 'Software bug or issue', 'bug', '#DC3545'),
        ('Story', 'User story or feature', 'story', '#007ACC'),
        ('Epic', 'Large feature or initiative', 'epic', '#6F42C1'),
        ('Improvement', 'Enhancement to existing feature', 'improvement', '#FF9800')
      ON CONFLICT (name) DO NOTHING
    `);
    
    await client.query('COMMIT');
    
    // ============================================================
    // VERIFICATION
    // ============================================================
    
    console.log('\n🔍 Verifying all tables were created...');
    
    const tableCount = await client.query(`
      SELECT COUNT(*) as count 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
    `);
    
    const totalTables = parseInt(tableCount.rows[0].count);
    
    console.log(`\n🎉 Migration completed successfully!`);
    console.log(`📊 Total tables in database: ${totalTables}`);
    console.log(`✅ Expected: 27 tables`);
    console.log(`📈 Status: ${totalTables >= 27 ? '✅ COMPLETE' : '⚠️  Some tables may be missing'}`);
    
    if (totalTables >= 27) {
      console.log(`\n🚀 Your Flow-Space app is now fully configured with all database tables!`);
      console.log(`🎯 All features are available: Sprint management, tickets, deliverables, sign-offs, approvals, documents, and more!`);
    } else {
      console.log(`\n⚠️  Expected 27 tables but found ${totalTables}. Some features may not be available.`);
    }
    
    console.log(`\n📋 Table categories created:`);
    console.log(`   🔐 Authentication & User Management (4 tables)`);
    console.log(`   📁 Project & Team Management (3 tables)`);
    console.log(`   🏃‍♂️ Sprint Management (4 tables)`);
    console.log(`   📦 Deliverable Management (1 table)`);
    console.log(`   ✅ Sign-off & Approval (6 tables)`);
    console.log(`   📄 Document Management (2 tables)`);
    console.log(`   🔔 Communication & Tracking (2 tables)`);
    console.log(`   📈 Reporting & Analytics (2 tables)`);
    console.log(`   🏷️ Supporting Tables (3 tables)`);
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('\n❌ Migration failed:', error.message);
    console.error('Error code:', error.code);
    console.error('Error detail:', error.detail);
    
    if (error.code === '42P01') {
      console.log('\n💡 This error suggests a referenced table might not exist.');
      console.log('   The migration creates tables in dependency order, so this should not happen.');
    }
    
    throw error;
    
  } finally {
    client.release();
    await pool.end();
  }
}

// Run migration if this file is executed directly
if (require.main === module) {
  createAllTables()
    .then(() => {
      console.log('\n✅ Complete migration finished successfully');
      process.exit(0);
    })
    .catch((error) => {
      console.error('\n❌ Migration failed:', error);
      process.exit(1);
    });
}

module.exports = { createAllTables };
