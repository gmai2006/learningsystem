CREATE SCHEMA IF NOT EXISTS learningsystem;

-- Core User & Identity Management
-- ENUM for User Roles
CREATE TYPE learningsystem.user_role AS ENUM ('STUDENT', 'FACULTY', 'STAFF', 'EMPLOYER');

CREATE TABLE learningsystem.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    okta_id VARCHAR(255) UNIQUE NOT NULL, -- Links to Okta/SSO
    banner_id VARCHAR(50) UNIQUE,         -- Links to Banner Data
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role learningsystem.user_role NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Student specific data
CREATE TABLE learningsystem.student_profiles (
    user_id UUID PRIMARY KEY REFERENCES learningsystem.users(id),
    major VARCHAR(255),
    gpa NUMERIC(3, 2),
    work_study_eligible BOOLEAN DEFAULT FALSE, -- Critical for filtering jobs [cite: 81-82]
    graduation_year INT,
    resume_url TEXT, -- Link to stored file
    portfolio_url TEXT -- Student career portfolio [cite: 97]
);

-- Employer specific data
CREATE TABLE learningsystem.employer_profiles (
    user_id UUID PRIMARY KEY REFERENCES learningsystem.users(id) ON DELETE CASCADE,
    company_name VARCHAR(255) NOT NULL,
    website_url VARCHAR(255), -- Added to support external recruitment links
    industry VARCHAR(100),
    description TEXT,
    is_approved BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Applied Learning Management
CREATE TYPE learningsystem.learning_type AS ENUM (
    'INTERNSHIP', 'PRACTICUM', 'CLINICAL', 'CO_OP',
    'STUDENT_EMPLOYMENT', 'RESEARCH', 'FIELD_WORK', 'FELLOWSHIP',
    'STUDY_ABROAD', 'VOLUNTEERISM', 'COMMUNITY_PROJECT',
    'SERVICE_LEARNING', 'CLASSROOM_SIMULATION', 'LAB_WORK',
    'ARTS_PERFORMANCE', 'APPRENTICESHIP'
);

CREATE TABLE learningsystem.applied_learning_experiences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES learningsystem.users(id),
    faculty_advisor_id UUID REFERENCES learningsystem.users(id),
    type learningsystem.learning_type NOT NULL,
    title VARCHAR(255) NOT NULL,
    organization_name VARCHAR(255),

    -- Status tracking
    status VARCHAR(50) DEFAULT 'DRAFT', -- DRAFT, PENDING, APPROVED, COMPLETED
    start_date DATE,
    end_date DATE,

    -- Sync with Canvas Courses for Service Learning [cite: 89-90]
    canvas_course_id VARCHAR(50),

    -- JSONB column for dynamic fields specific to the 16 types
    type_specific_data JSONB,

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Workflow & "No-Login" Approvals
CREATE TABLE learningsystem.workflows (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    experience_id UUID NOT NULL REFERENCES learningsystem.applied_learning_experiences(id),
    step_order INT NOT NULL, -- 1 = Supervisor, 2 = Dept Chair, etc.
    approver_email VARCHAR(255) NOT NULL, -- External or Internal email
    approver_name VARCHAR(255),

    -- Security for external approvers (emailed link authentication)
    auth_token VARCHAR(255),
    token_expiry TIMESTAMP,

    status VARCHAR(50) DEFAULT 'PENDING', -- PENDING, APPROVED, REJECTED
    comments TEXT,
    action_date TIMESTAMP
);

-- Career Services (Jobs & Events)
CREATE TABLE learningsystem.job_postings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    employer_id UUID NOT NULL REFERENCES learningsystem.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    location VARCHAR(255), -- Added to support office address or campus site
    funding_source VARCHAR(50) DEFAULT 'NON_WORK_STUDY',
    is_on_campus BOOLEAN DEFAULT FALSE,
    deadline DATE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE learningsystem.events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizer_id UUID REFERENCES learningsystem.users(id),
    title VARCHAR(255),
    type VARCHAR(50), -- Career Fair, Workshop, Info Session
    location VARCHAR(255),
    start_time TIMESTAMP,
    end_time TIMESTAMP,

    -- Fee management for events requiring payment (e.g., Alternative Service Breaks) [cite: 93]
    requires_fee BOOLEAN DEFAULT FALSE,
    fee_amount NUMERIC(10, 2),
    touchnet_payment_code VARCHAR(100) -- Reference for eCommerce integration
);

CREATE TABLE learningsystem.event_registrations (
    event_id UUID REFERENCES learningsystem.events(id),
    user_id UUID REFERENCES learningsystem.users(id),
    payment_status VARCHAR(50), -- PAID, PENDING, WAIVED
    checked_in BOOLEAN DEFAULT FALSE,
    PRIMARY KEY (event_id, user_id)
);

-- Volunteer & Impact Tracking
CREATE TABLE learningsystem.volunteer_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID REFERENCES learningsystem.users(id),
    experience_id UUID REFERENCES learningsystem.applied_learning_experiences(id),

    date_logged DATE NOT NULL,
    hours_worked NUMERIC(5, 2),

    -- Tracking non-volunteer impacts (Philanthropy, Voting, etc.) [cite: 91]
    impact_type VARCHAR(50), -- 'HOURS', 'DONATION', 'VOTING', 'PHILANTHROPY'
    donation_amount NUMERIC(10, 2), -- Capture financial value if applicable

    -- Verification
    site_supervisor_email VARCHAR(255),
    is_verified BOOLEAN DEFAULT FALSE
);

--
-- Audit Log table within the 'learningsystem' schema
CREATE TABLE learningsystem.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID REFERENCES learningsystem.users(id) ON DELETE SET NULL,
    actor_name VARCHAR(255) NOT NULL, -- Stored as a snapshot to handle deleted users
    action VARCHAR(255) NOT NULL,    -- e.g., "POSTED_JOB", "VERIFIED_EXPERIENCE"
    target_type VARCHAR(50) NOT NULL, -- e.g., "JOB", "LEARNING", "USER"
    target_id UUID,                  -- ID of the entity being acted upon
    details TEXT,                    -- JSON or string describing the change
    ip_address VARCHAR(45),          -- Supports IPv4 and IPv6 for security auditing
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for high-performance retrieval of the "System Pulse" feed
CREATE INDEX idx_audit_logs_created_at ON learningsystem.audit_logs (created_at DESC);

-- Index for filtering by entity type (useful for reporting)
CREATE INDEX idx_audit_logs_target_type ON learningsystem.audit_logs (target_type);

-- Table to store global system parameters
CREATE TABLE learningsystem.system_configs (
    config_key VARCHAR(100) PRIMARY KEY,
    config_value TEXT NOT NULL,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_by UUID REFERENCES learningsystem.users(id)
);

