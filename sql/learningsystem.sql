CREATE SCHEMA IF NOT EXISTS learningsystem;

-- Core User & Identity Management
-- ENUM for User Roles
CREATE TYPE learningsystem.user_role AS ENUM ('STUDENT', 'FACULTY', 'STAFF', 'EMPLOYER');

CREATE TABLE learningsystem.users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    okta_id VARCHAR(255) UNIQUE, -- Links to Okta/SSO
    banner_id VARCHAR(50) UNIQUE,         -- Links to Banner Data
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    role learningsystem.user_role NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE learningsystem.users
    ALTER COLUMN okta_id DROP NOT NULL,
    ALTER COLUMN banner_id DROP NOT NULL;

-- Ensure uniqueness while allowing multiple NULLs
CREATE UNIQUE INDEX idx_user_okta_id ON learningsystem.users (okta_id) WHERE okta_id IS NOT NULL;
CREATE UNIQUE INDEX idx_user_banner_id ON learningsystem.users (banner_id) WHERE banner_id IS NOT NULL;

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

ALTER TABLE learningsystem.student_profiles
    ADD COLUMN bio TEXT,
    ADD COLUMN linkedin_url TEXT,
    ADD COLUMN github_url TEXT,
    ADD COLUMN profile_verified BOOLEAN DEFAULT FALSE,
    ADD COLUMN updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- Skills are best handled in a separate 'join' table to allow
-- for easy searching/filtering by employers.
CREATE TABLE learningsystem.student_skills (
    user_id UUID REFERENCES learningsystem.users(id) ON DELETE CASCADE,
    skill_name VARCHAR(100),
    PRIMARY KEY (user_id, skill_name)
);

-- Use TEXT to accommodate the long Base64 string
ALTER TABLE learningsystem.student_profiles
ADD COLUMN profile_picture_base64 TEXT;

-- Update the view to include the Base64 field
CREATE OR REPLACE VIEW learningsystem.vw_student_profiles AS
SELECT
    u.id AS user_id,
    u.first_name,
    u.last_name,
    u.email,
    sp.major,
    sp.gpa,
    sp.work_study_eligible,
    sp.graduation_year,
    sp.bio,
    sp.resume_url,
    sp.portfolio_url,
    sp.linkedin_url,
    sp.github_url,
    sp.profile_picture_base64 -- The Base64 string
FROM learningsystem.users u
JOIN learningsystem.student_profiles sp ON u.id = sp.user_id;

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
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP WITH TIME ZONE
);

--ALTER TABLE learningsystem.applied_learning_experiences
--ADD COLUMN is_verified BOOLEAN DEFAULT FALSE,
--ADD COLUMN verified_at TIMESTAMP WITH TIME ZONE;

-- Optional: If you already have data, you might want to sync it
UPDATE learningsystem.applied_learning_experiences
SET is_verified = TRUE
WHERE verified_at IS NOT NULL;

CREATE INDEX idx_experiences_jsonb_data
ON learningsystem.applied_learning_experiences
USING GIN (type_specific_data);

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

CREATE TABLE learningsystem.job_applications (
    id UUID PRIMARY KEY,
    job_id UUID NOT NULL,
    student_id UUID NOT NULL,
    status VARCHAR(50) DEFAULT 'PENDING',
    notes TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints to ensure data integrity
    CONSTRAINT fk_job FOREIGN KEY (job_id) REFERENCES learningsystem.job_postings(id) ON DELETE CASCADE,
    CONSTRAINT fk_student FOREIGN KEY (student_id) REFERENCES learningsystem.users(id) ON DELETE CASCADE,
    -- Prevent duplicate applications for the same job by the same student
    CONSTRAINT unique_student_job UNIQUE (student_id, job_id)
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
    deleted_at TIMESTAMP
);

ALTER TABLE learningsystem.job_postings
ADD COLUMN category VARCHAR(100) DEFAULT 'General';

-- Optional: Update existing jobs to better categories
UPDATE learningsystem.job_postings SET category = 'Engineering' WHERE title ILIKE '%engineer%';
UPDATE learningsystem.job_postings SET category = 'Marketing' WHERE title ILIKE '%marketing%';

-- Add the missing recruitment fields
ALTER TABLE learningsystem.job_postings
ADD COLUMN salary_range VARCHAR(100),
ADD COLUMN requirements TEXT;

-- Optional: Add a comment to help other developers
COMMENT ON COLUMN learningsystem.job_postings.requirements IS 'HTML or Markdown supported list of job prerequisites';

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

-- The catalog of available learning content
CREATE TABLE learningsystem.learning_modules (
    id UUID PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(50), -- e.g., 'RESUME', 'INTERVIEW'
    module_type VARCHAR(20), -- e.g., 'VIDEO', 'DOCUMENT'
    duration_minutes INT,
    content_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE learningsystem.learning_modules ADD COLUMN weight INT DEFAULT 10;
-- High Weight: Resume & Direct Outcomes
UPDATE learningsystem.learning_modules SET weight = 40 WHERE category = 'RESUME';
UPDATE learningsystem.learning_modules SET weight = 30 WHERE category = 'INTERVIEW';

-- Medium Weight: Networking & Social
UPDATE learningsystem.learning_modules SET weight = 20 WHERE category = 'SOCIAL';
UPDATE learningsystem.learning_modules SET weight = 15 WHERE category = 'NETWORKING';

-- Low Weight: FAQs & Minor Documents
UPDATE learningsystem.learning_modules SET weight = 10 WHERE category = 'EMPLOYMENT';

-- Tracking table for student progress
CREATE TABLE learningsystem.student_module_completions (
    student_id UUID NOT NULL,
    module_id UUID NOT NULL,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (student_id, module_id),
    CONSTRAINT fk_student FOREIGN KEY (student_id) REFERENCES learningsystem.users(id) ON DELETE CASCADE,
    CONSTRAINT fk_module FOREIGN KEY (module_id) REFERENCES learningsystem.learning_modules(id) ON DELETE CASCADE
);