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

-- 1. Insert a PENDING Internship (Unverified)
INSERT INTO learningsystem.applied_learning_experiences (
    id,
    student_id,
    faculty_advisor_id,
    type,
    title,
    organization_name,
    status,
    start_date,
    end_date,
    type_specific_data,
    is_verified,
    created_at
) VALUES (
    gen_random_uuid(),
    (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1),
    (SELECT id FROM learningsystem.users WHERE role = 'FACULTY' ORDER BY random() LIMIT 1),
    'INTERNSHIP',
    'Junior Software Developer',
    'F5 Networks',
    'PENDING',
    '2026-01-05',
    '2026-05-15',
    '{"credit_hours": 4, "mentor_name": "Jane Doe", "department": "Cloud Services"}',
    FALSE,
    NOW() - INTERVAL '3 days'
);

-- 2. Insert an APPROVED Research Project (Verified)
INSERT INTO learningsystem.applied_learning_experiences (
    id,
    student_id,
    faculty_advisor_id,
    type,
    title,
    organization_name,
    status,
    start_date,
    end_date,
    type_specific_data,
    is_verified,
    verified_at,
    created_at
) VALUES (
    gen_random_uuid(),
    (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1),
    (SELECT id FROM learningsystem.users WHERE role = 'FACULTY' ORDER BY random() LIMIT 1),
    'RESEARCH',
    'Biochemical Soil Analysis',
    'EWU Biology Lab',
    'APPROVED',
    '2025-09-01',
    '2025-12-15',
    '{"grant_funded": true, "lab_number": "S-304", "publication_target": "Nature Journal"}',
    TRUE,
    NOW() - INTERVAL '1 day',
    NOW() - INTERVAL '15 days'
);

-- 3. Insert a COMPLETED Service Learning experience with Canvas ID
INSERT INTO learningsystem.applied_learning_experiences (
    id,
    student_id,
    faculty_advisor_id,
    type,
    title,
    organization_name,
    status,
    canvas_course_id,
    type_specific_data,
    is_verified,
    verified_at,
    created_at
) VALUES (
    gen_random_uuid(),
    (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1),
    (SELECT id FROM learningsystem.users WHERE role = 'FACULTY' ORDER BY random() LIMIT 1),
    'SERVICE_LEARNING',
    'Youth Literacy Tutor',
    'Spokane Public Schools',
    'COMPLETED',
    'CANV-10293',
    '{"hours_completed": 40, "community_partner_contact": "John Smith"}',
    TRUE,
    NOW() - INTERVAL '5 days',
    NOW() - INTERVAL '60 days'
);

SELECT
    u.last_name AS student_name,
    e.type,
    e.status,
    e.is_verified,
    e.type_specific_data->>'mentor_name' AS mentor
FROM learningsystem.applied_learning_experiences e
JOIN learningsystem.users u ON e.student_id = u.id;

-- 1. INTERNSHIP
INSERT INTO learningsystem.applied_learning_experiences (id, student_id, type, title, organization_name, status, type_specific_data)
VALUES (gen_random_uuid(), (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1), 'INTERNSHIP', 'Cybersecurity Analyst Intern', 'F5 Networks', 'PENDING', '{"credit_hours": 5, "mentor": "Jane Smith", "stipend": 2000}');

-- 2. PRACTICUM
INSERT INTO learningsystem.applied_learning_experiences (id, student_id, type, title, organization_name, status, type_specific_data)
VALUES (gen_random_uuid(), (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1), 'PRACTICUM', 'K-12 Teaching Practicum', 'Cheney School District', 'APPROVED', '{"classroom_grade": "4th", "observation_hours": 40}');

-- 3. CLINICAL
INSERT INTO learningsystem.applied_learning_experiences (id, student_id, type, title, organization_name, status, type_specific_data)
VALUES (gen_random_uuid(), (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1), 'CLINICAL', 'Nursing Rotation - ICU', 'Providence Sacred Heart', 'APPROVED', '{"unit": "Critical Care", "clinical_instructor": "Dr. Miller", "total_shifts": 12}');

-- 4. CO_OP
INSERT INTO learningsystem.applied_learning_experiences (id, student_id, type, title, organization_name, status, type_specific_data)
VALUES (gen_random_uuid(), (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1), 'CO_OP', 'Engineering Cooperative Program', 'Boeing', 'PENDING', '{"term": "Spring 2026", "department": "Aerospace Design", "is_paid": true}');

-- 5. STUDENT_EMPLOYMENT
INSERT INTO learningsystem.applied_learning_experiences (id, student_id, type, title, organization_name, status, type_specific_data)
VALUES (gen_random_uuid(), (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1), 'STUDENT_EMPLOYMENT', 'IT Help Desk Assistant', 'EWU IT Services', 'COMPLETED', '{"supervisor": "Bill Gates", "hours_per_week": 15}');

-- 6. RESEARCH
INSERT INTO learningsystem.applied_learning_experiences (id, student_id, type, title, organization_name, status, type_specific_data)
VALUES (gen_random_uuid(), (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1), 'RESEARCH', 'Soil Nutrient Analysis Research', 'EWU Environmental Lab', 'APPROVED', '{"lab_id": "S-201", "grant_number": "NSF-8892", "is_published": false}');

-- 7. FIELD_WORK
INSERT INTO learningsystem.applied_learning_experiences (id, student_id, type, title, organization_name, status, type_specific_data)
VALUES (gen_random_uuid(), (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1), 'FIELD_WORK', 'Geological Surveying', 'Turnbull Wildlife Refuge', 'PENDING', '{"equipment_used": "GPS, Soil Probe", "permit_id": "TW-002"}');

-- 8. FELLOWSHIP
INSERT INTO learningsystem.applied_learning_experiences (id, student_id, type, title, organization_name, status, type_specific_data)
VALUES (gen_random_uuid(), (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1), 'FELLOWSHIP', 'Graduate Leadership Fellowship', 'EWU Foundation', 'APPROVED', '{"cohort_name": "Leaders 2025", "award_amount": 5000}');

-- 9. STUDY_ABROAD
INSERT INTO learningsystem.applied_learning_experiences (id, student_id, type, title, organization_name, status, type_specific_data)
VALUES (gen_random_uuid(), (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1), 'STUDY_ABROAD', 'History of Art in Florence', 'University of Florence', 'APPROVED', '{"country": "Italy", "language_of_instruction": "Italian", "credits_transferable": true}');

-- 10. VOLUNTEERISM
INSERT INTO learningsystem.applied_learning_experiences (id, student_id, type, title, organization_name, status, type_specific_data)
VALUES (gen_random_uuid(), (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1), 'VOLUNTEERISM', 'Weekend Food Bank Support', 'Second Harvest', 'COMPLETED', '{"impact_area": "Food Insecurity", "total_hours": 50}');

-- 11. COMMUNITY_PROJECT
INSERT INTO learningsystem.applied_learning_experiences (id, student_id, type, title, organization_name, status, type_specific_data)
VALUES (gen_random_uuid(), (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1), 'COMMUNITY_PROJECT', 'Mural Restoration', 'City of Cheney', 'PENDING', '{"community_partner": "Downtown Arts", "location": "1st Street"}');

-- 12. SERVICE_LEARNING
INSERT INTO learningsystem.applied_learning_experiences (id, student_id, type, title, organization_name, status, type_specific_data)
VALUES (gen_random_uuid(), (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1), 'SERVICE_LEARNING', 'Literacy Outreach', 'Spokane Public Library', 'APPROVED', '{"canvas_course_id": "ENGL-101", "is_mandatory": true}');

-- 13. CLASSROOM_SIMULATION
INSERT INTO learningsystem.applied_learning_experiences (id, student_id, type, title, organization_name, status, type_specific_data)
VALUES (gen_random_uuid(), (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1), 'CLASSROOM_SIMULATION', 'Mock Trial - Criminal Law', 'EWU Law Society', 'COMPLETED', '{"role_played": "Prosecutor", "case_topic": "Property Law"}');

-- 14. LAB_WORK
INSERT INTO learningsystem.applied_learning_experiences (id, student_id, type, title, organization_name, status, type_specific_data)
VALUES (gen_random_uuid(), (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1), 'LAB_WORK', 'Advanced Circuit Testing', 'Engineering Lab 4', 'APPROVED', '{"bench_number": 12, "safety_certified": true}');

-- 15. ARTS_PERFORMANCE
INSERT INTO learningsystem.applied_learning_experiences (id, student_id, type, title, organization_name, status, type_specific_data)
VALUES (gen_random_uuid(), (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1), 'ARTS_PERFORMANCE', 'Senior Jazz Ensemble', 'EWU Recital Hall', 'COMPLETED', '{"instrument": "Tenor Sax", "repertoire": "Coltrane Basics"}');

-- 16. APPRENTICESHIP
INSERT INTO learningsystem.applied_learning_experiences (id, student_id, type, title, organization_name, status, type_specific_data)
VALUES (gen_random_uuid(), (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1), 'APPRENTICESHIP', 'Master HVAC Training', 'McKinstry', 'PENDING', '{"journeyman_license": "A-9923", "phase": "Level 1 Induction"}');

SELECT
    type,
    title,
    type_specific_data->>'total_hours' as hours,
    type_specific_data->>'is_paid' as paid
FROM learningsystem.applied_learning_experiences;

INSERT INTO learningsystem.learning_modules
(id, title, description, category, module_type, duration_minutes, content_url, is_active)
VALUES
-- Module 1: Resume Building
('3a1b2c3d-4e5f-6a7b-8c9d-0e1f2a3b4c5d',
 'The Eagle Resume Framework',
 'Learn how to structure your resume specifically for EWU handshake and regional employers. Includes action-verb strategies.',
 'RESUME', 'DOCUMENT', 15, 'https://silo.ewu.edu/resources/resume-framework.pdf', true),

-- Module 2: Interview Prep
('4b2c3d4e-5f6a-7b8c-9d0e-1f2a3b4c5d6e',
 'STAR Method Interviewing',
 'A deep dive into Situational, Task, Action, and Result (STAR) techniques for behavioral interviews.',
 'INTERVIEW', 'VIDEO', 12, 'https://silo.ewu.edu/learning/star-method-video', true),

-- Module 3: Social Media / LinkedIn
('5c3d4e5f-6a7b-8c9d-0e1f-2a3b4c5d6e7f',
 'LinkedIn Profile Optimization',
 'How to attract recruiters in the Pacific Northwest by optimizing your headline, summary, and EWU alumni connections.',
 'SOCIAL', 'INTERACTIVE', 20, 'https://silo.ewu.edu/interactive/linkedin-guide', true),

-- Module 4: Networking
('6d4e5f6a-7b8c-9d0e-1f2a-3b4c5d6e7f8a',
 'Networking 101: The Elevator Pitch',
 'Construct a 30-second professional introduction for career fairs and networking events.',
 'NETWORKING', 'VIDEO', 8, 'https://silo.ewu.edu/learning/elevator-pitch-mastery', true),

-- Module 5: Federal Work Study
('7e5f6a7b-8c9d-0e1f-2a3b-4c5d6e7f8a9b',
 'Navigating Work Study at EWU',
 'A guide for students eligible for Federal Work Study. Learn how to verify your status and apply for campus-specific roles.',
 'EMPLOYMENT', 'DOCUMENT', 10, 'https://silo.ewu.edu/resources/work-study-faq.pdf', true);

 -- High Weight: Resume & Direct Outcomes
 UPDATE learningsystem.learning_modules SET weight = 40 WHERE category = 'RESUME';
 UPDATE learningsystem.learning_modules SET weight = 30 WHERE category = 'INTERVIEW';

 -- Medium Weight: Networking & Social
 UPDATE learningsystem.learning_modules SET weight = 20 WHERE category = 'SOCIAL';
 UPDATE learningsystem.learning_modules SET weight = 15 WHERE category = 'NETWORKING';

 -- Low Weight: FAQs & Minor Documents
 UPDATE learningsystem.learning_modules SET weight = 10 WHERE category = 'EMPLOYMENT';