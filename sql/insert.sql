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

-- 1. On-Campus Peer Mentoring
INSERT INTO learningsystem.job_postings (
    id, employer_id, title, description, location,
    category, salary_range, requirements, funding_source,
    is_on_campus, deadline, is_active, created_at
) VALUES (
             gen_random_uuid(),
             '753d7730-5d88-45a3-a5a7-bf7c3cfa643e', -- Replace with a valid employer UUID
             'Eagle Peer Mentor',
             'Help incoming freshmen navigate campus life. Provide guidance on study habits and EWU resources.',
             'Showalter Hall',
             'Volunteer',
             'Unpaid / Service Hours',
             'Must be a sophomore or higher with a 3.0 GPA.',
             'Departmental',
             TRUE,
             CURRENT_DATE + INTERVAL '30 days',
             TRUE,
             NOW()
         );

-- 2. Local Community Food Bank
INSERT INTO learningsystem.job_postings (
    id, employer_id, title, description, location,
    category, salary_range, requirements, funding_source,
    is_on_campus, deadline, is_active, created_at
) VALUES (
             gen_random_uuid(),
             '753d7730-5d88-45a3-a5a7-bf7c3cfa643e', -- Replace with a valid employer UUID
             'Food Distribution Assistant',
             'Assist in sorting and distributing grocery items to local families. Great for students looking for weekend service hours.',
             'Cheney Community Center',
             'Volunteer',
             'Unpaid',
             'Must be able to lift 25 lbs. Friendly attitude required.',
             'Private',
             FALSE,
             CURRENT_DATE + INTERVAL '60 days',
             TRUE,
             NOW()
         );

-- 3. Sustainability / Campus Garden
INSERT INTO learningsystem.job_postings (
    id, employer_id, title, description, location,
    category, salary_range, requirements, funding_source,
    is_on_campus, deadline, is_active, created_at
) VALUES (
             gen_random_uuid(),
             '753d7730-5d88-45a3-a5a7-bf7c3cfa643e', -- Replace with a valid employer UUID
             'Campus Garden Lead',
             'Maintain the student community garden. Learn about sustainable agriculture while earning volunteer credits.',
             'EWU Campus Labs',
             'Volunteer',
             'Service Credits',
             'Interest in biology or sustainability preferred.',
             'Grant',
             TRUE,
             CURRENT_DATE + INTERVAL '15 days',
             TRUE,
             NOW()
         );

-- 1. Simulate a 'Talent Search' view from a random employer to a random student
INSERT INTO learningsystem.profile_access_logs (id, student_id, employer_id, accessed_at, access_context)
VALUES (
           gen_random_uuid(),
           (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1),
       (SELECT id FROM learningsystem.users WHERE role = 'EMPLOYER' ORDER BY random() LIMIT 1),
            CURRENT_TIMESTAMP - INTERVAL '2 hours',
    'TALENT_SEARCH'
    );

-- 2. Simulate an 'Application Review' view (Accessing a student who applied)
INSERT INTO learningsystem.profile_access_logs (id, student_id, employer_id, accessed_at, access_context)
VALUES (
           gen_random_uuid(),
           (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1),
       (SELECT id FROM learningsystem.users WHERE role = 'EMPLOYER' ORDER BY random() LIMIT 1),
            CURRENT_TIMESTAMP - INTERVAL '1 day',
    'APPLICATION_REVIEW'
    );

-- 3. Simulate a historical view from 3 days ago
INSERT INTO learningsystem.profile_access_logs (id, student_id, employer_id, accessed_at, access_context)
VALUES (
           gen_random_uuid(),
           (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1),
       (SELECT id FROM learningsystem.users WHERE role = 'EMPLOYER' ORDER BY random() LIMIT 1),
            CURRENT_TIMESTAMP - INTERVAL '3 days',
    'TALENT_SEARCH'
    );

-- 4. Simulate a view for a 'Career Fair' follow-up
INSERT INTO learningsystem.profile_access_logs (id, student_id, employer_id, accessed_at, access_context)
VALUES (
           gen_random_uuid(),
           (SELECT id FROM learningsystem.users WHERE role = 'STUDENT' ORDER BY random() LIMIT 1),
       (SELECT id FROM learningsystem.users WHERE role = 'EMPLOYER' ORDER BY random() LIMIT 1),
            CURRENT_TIMESTAMP - INTERVAL '5 hours',
    'CAREER_FAIR_DISCOVERY'
    );


DO $$
DECLARE
student_record RECORD;
    employer_record RECORD;
    i INT;
    random_days INT;
    random_hours INT;
    contexts TEXT[] := ARRAY['TALENT_SEARCH', 'APPLICATION_REVIEW', 'CAREER_FAIR_DISCOVERY', 'RESUME_DOWNLOAD'];
BEGIN
FOR i IN 1..50 LOOP
        -- Select a random student
SELECT id INTO student_record FROM learningsystem.users
WHERE role = 'STUDENT' ORDER BY random() LIMIT 1;

-- Select a random employer
SELECT id INTO employer_record FROM learningsystem.users
WHERE role = 'EMPLOYER' ORDER BY random() LIMIT 1;

-- Generate a random timestamp within the last 30 days
random_days := floor(random() * 30);
        random_hours := floor(random() * 24);

        -- Insert the log entry
        IF student_record.id IS NOT NULL AND employer_record.id IS NOT NULL THEN
            INSERT INTO learningsystem.profile_access_logs (
                id,
                student_id,
                employer_id,
                accessed_at,
                access_context
            ) VALUES (
                gen_random_uuid(),
                student_record.id,
                employer_record.id,
                (CURRENT_TIMESTAMP - (random_days || ' days')::interval - (random_hours || ' hours')::interval),
                contexts[floor(random() * array_length(contexts, 1)) + 1]
            );
END IF;
END LOOP;
END $$;

DO $$
DECLARE
org_id UUID;
    i INT;
    event_types TEXT[] := ARRAY['INFO_SESSION', 'WORKSHOP', 'CAREER_FAIR', 'NETWORKING'];
    titles TEXT[] := ARRAY[
        'Amazon: Software Engineering Info Session',
        'Resume Building for Tech Careers',
        'Eastern Washington Spring Career Fair',
        'Google: Cloud Architecture Workshop',
        'Spokane Tech Networking Mixer',
        'Mock Interview Marathon'
    ];
BEGIN
FOR i IN 1..10 LOOP
        -- Select a random organizer (Employer or Admin)
SELECT id INTO org_id FROM learningsystem.users
WHERE role IN ('EMPLOYER', 'STAFF') ORDER BY random() LIMIT 1;

IF org_id IS NOT NULL THEN
            INSERT INTO learningsystem.events (
                id,
                organizer_id,
                title,
                description,
                type,
                location,
                is_virtual,
                meeting_link,
                start_time,
                end_time,
                capacity,
                current_rsrv_count,
                requires_fee,
                fee_amount,
                touchnet_payment_code,
                is_active
            ) VALUES (
                gen_random_uuid(),
                org_id,
                titles[floor(random() * array_length(titles, 1)) + 1],
                'Join us for an engaging session designed to help students bridge the gap between academia and industry. Open to all majors.',
                event_types[floor(random() * array_length(event_types, 1)) + 1],
                CASE WHEN (random() > 0.5) THEN 'EWU PUB Room ' || floor(random() * 300 + 100) ELSE 'Virtual Session' END,
                (random() > 0.5),
                CASE WHEN (random() > 0.5) THEN 'https://zoom.us/j/' || floor(random() * 900000000 + 100000000) ELSE NULL END,
                -- Mix of past events and future events (last 10 days to next 30 days)
                CURRENT_TIMESTAMP + (random() * 40 - 10 || ' days')::interval,
                CURRENT_TIMESTAMP + (random() * 40 - 10 || ' days')::interval + '2 hours'::interval,
                floor(random() * 100 + 20),
                floor(random() * 15),
                (random() > 0.8), -- 20% chance of requiring a fee
                CASE WHEN (random() > 0.8) THEN (random() * 50 + 10)::numeric(10,2) ELSE 0 END,
                CASE WHEN (random() > 0.8) THEN 'ASB-' || floor(random() * 9000 + 1000) ELSE NULL END,
                TRUE
            );
END IF;
END LOOP;
END $$;

-- 1. Software Engineering Internship at Amazon (Assuming employer_id UUID exists)
INSERT INTO learningsystem.job_postings (
    id,
    employer_id,
    title,
    description,
    location,
    category,
    salary_range,
    created_at
) VALUES (
             gen_random_uuid(),
             '483ab23e-8436-4a85-a4c0-e722948fdf2a', -- Replace with a valid employer_id
             'Software Engineering Practicum',
             'Join our cloud infrastructure team for a 3-month intensive coding internship.',
             'Seattle, WA',
             'INTERNSHIP',
             '$35 - $45 / hr',
             CURRENT_TIMESTAMP
         );

-- 2. Marketing Internship at local Non-Profit
INSERT INTO learningsystem.job_postings (
    id,
    employer_id,
    title,
    description,
    location,
    category,
    salary_range,
    created_at
) VALUES (
             gen_random_uuid(),
             '483ab23e-8436-4a85-a4c0-e722948fdf2a', -- Replace with a valid employer_id
             'Digital Marketing & Outreach Intern',
             'Help manage social media presence and community engagement for local youth programs.',
             'Cheney, WA',
             'INTERNSHIP',
             'Unpaid / Academic Credit',
             CURRENT_TIMESTAMP
         );

-- 3. Healthcare Administration Internship
INSERT INTO learningsystem.job_postings (
    id,
    employer_id,
    title,
    description,
    location,
    category,
    salary_range,
    created_at
) VALUES (
             gen_random_uuid(),
             '483ab23e-8436-4a85-a4c0-e722948fdf2a', -- Replace with a valid employer_id
             'Healthcare Admin Practicum',
             'Support hospital operations and patient flow management in a clinical environment.',
             'Spokane, WA',
             'INTERNSHIP',
             'Stipend Provided',
             CURRENT_TIMESTAMP
         );