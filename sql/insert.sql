-- 1. Student User (Integrated with Banner for FERPA/Enrollment)
INSERT INTO learningsystem.users (
    okta_id,
    banner_id,
    email,
    first_name,
    last_name,
    role,
    is_active
) VALUES (
    'okta_001_student',
    '800123456',
    'aeagle@ewu.edu',
    'Alice',
    'Eagle',
    'STUDENT',
    TRUE
);

-- 2. Staff User (Administers Career Fairs and Marketing Campaigns)
INSERT INTO learningsystem.users (
    okta_id,
    banner_id,
    email,
    first_name,
    last_name,
    role,
    is_active
) VALUES (
    'okta_002_staff',
    '800987654',
    'jstaff@ewu.edu',
    'Jordan',
    'Stafford',
    'STAFF',
    TRUE
);

-- 3. Faculty User (Oversight for the 16 Applied Learning Types)
INSERT INTO learningsystem.users (
    okta_id,
    banner_id,
    email,
    first_name,
    last_name,
    role,
    is_active
) VALUES (
    'okta_003_faculty',
    '800555000',
    'fpro@ewu.edu',
    'Felicia',
    'Professor',
    'FACULTY',
    TRUE
);

-- 4. Employer Partner (Discrete account for external recruitment tools)
INSERT INTO learningsystem.users (
    okta_id,
    banner_id,
    email,
    first_name,
    last_name,
    role,
    is_active
) VALUES (
    'okta_004_employer',
    NULL, -- Employers typically do not have a Banner ID
    'recruiting@spokanetech.com',
    'Sam',
    'Snyder',
    'EMPLOYER',
    TRUE
);
-- 1. Student Profile for Alice Eagle (linking to the previously created user)
-- Note: In a real scenario, you would fetch the UUID generated for 'aeagle@ewu.edu'
INSERT INTO learningsystem.student_profiles (
    user_id,
    major,
    gpa,
    work_study_eligible,
    graduation_year,
    resume_url,
    portfolio_url
)
SELECT
    id,
    'Computer Science',
    3.85,
    TRUE, -- Student is eligible for FWS jobs
    2026,
    'https://storage.ewu.edu/resumes/aeagle_resume.pdf', --
    'https://portfolios.ewu.edu/aeagle' --
FROM learningsystem.users
WHERE email = 'aeagle@ewu.edu';

-- Employer Profile for Sam Snyder at Spokane Tech
INSERT INTO learningsystem.employer_profiles (
    user_id,
    company_name,
    website_url,
    industry,
    description,
    is_approved
)
SELECT
    id,
    'Spokane Tech Solutions',
    'https://spokanetech.com',
    'Information Technology',
    'A leading provider of cloud-native enterprise solutions in the Inland Northwest.',
    TRUE -- Set to TRUE if the Staff have already vetted this partner
FROM learningsystem.users
WHERE email = 'recruiting@spokanetech.com';

-- 1. Federal Work Study Position (Restricted Visibility)
INSERT INTO learningsystem.job_postings (
    employer_id, 
    title, 
    description, 
    funding_source, 
    is_on_campus, 
    location, 
    deadline, 
    is_active
) 
SELECT 
    id, 
    'Student IT Support Technician', 
    'Assist campus departments with software troubleshooting and hardware setup. Must be FWS eligible.', 
    'WORK_STUDY', 
    TRUE, 
    'EWU Cheney - JFK Library', 
    '2026-01-15', 
    TRUE
FROM learningsystem.users 
WHERE email = 'recruiting@spokanetech.com';

-- 2. Standard Internship (Public Visibility)
INSERT INTO learningsystem.job_postings (
    employer_id, 
    title, 
    description, 
    funding_source, 
    is_on_campus, 
    location, 
    deadline, 
    is_active
) 
SELECT 
    id, 
    'Software Engineering Intern', 
    'Join our cloud solutions team for a 12-week summer internship. Proficiency in Java or React preferred.', 
    'NON_WORK_STUDY', 
    FALSE, 
    'Downtown Spokane / Remote', 
    '2026-03-01', 
    TRUE
FROM learningsystem.users 
WHERE email = 'recruiting@spokanetech.com';

-- 1. Employer Activity (Spokane Tech)
INSERT INTO learningsystem.audit_logs (
    actor_id,
    actor_name,
    action,
    target_type,
    target_id,
    details,
    ip_address,
    created_at
)
SELECT
    id,
    'Sam Snyder',
    'POSTED_NEW_JOB',
    'JOB',
    gen_random_uuid(), -- Simulating a specific Job ID
    'Posted: Cloud Engineering Intern',
    '192.168.1.45',
    NOW() - INTERVAL '2 minutes'
FROM learningsystem.users
WHERE email = 'recruiting@spokanetech.com';

-- 2. Student Activity (Alice Eagle)
INSERT INTO learningsystem.audit_logs (
    actor_id,
    actor_name,
    action,
    target_type,
    target_id,
    details,
    ip_address,
    created_at
)
SELECT
    id,
    'Alice Eagle',
    'SUBMITTED_EXPERIENCE',
    'LEARNING',
    gen_random_uuid(),
    'Submitted: Summer Research Project',
    '172.16.254.1',
    NOW() - INTERVAL '15 minutes'
FROM learningsystem.users
WHERE email = 'aeagle@ewu.edu';

-- 3. System Activity (Automated Banner Sync)
INSERT INTO learningsystem.audit_logs (
    actor_name,
    action,
    target_type,
    details,
    ip_address,
    created_at
)
VALUES (
    'System Sync Service',
    'BANNER_REFRESH_COMPLETE',
    'SYSTEM',
    'Successfully synchronized 452 student academic records.',
    '127.0.0.1',
    NOW() - INTERVAL '1 hour'
);

-- 4. Staff Activity (Admin Action)
INSERT INTO learningsystem.audit_logs (
    actor_name,
    action,
    target_type,
    details,
    ip_address,
    created_at
)
VALUES (
    'Staff Administrator',
    'USER_ROLE_UPDATED',
    'USER',
    'Updated permissions for partner: Spokane Tech',
    '10.0.0.5',
    NOW() - INTERVAL '3 hours'
);

SELECT actor_name, action, target_type, created_at
FROM learningsystem.audit_logs
ORDER BY created_at DESC
LIMIT 5;

-- Seed initial data for the "Academic & Funding" settings
INSERT INTO learningsystem.system_configs (config_key, config_value, description) VALUES
('CURRENT_SEMESTER', 'Spring 2026', 'The active academic term for reporting.'),
('JOB_APPROVAL_REQUIRED', 'TRUE', 'Global toggle for vetting employer postings.'),
('FWS_CHECK_ENABLED', 'TRUE', 'Enforce Federal Work Study eligibility via Banner sync.'),
('EXPERIENCE_DEADLINE', '2026-05-15', 'Final date for students to submit learning logs.');