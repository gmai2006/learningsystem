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
    sp.profile_picture_base64,
    sp.is_ferpa_restricted
FROM learningsystem.users u
         JOIN learningsystem.student_profiles sp ON u.id = sp.user_id;

CREATE OR REPLACE VIEW learningsystem.v_job_oversight AS
SELECT
    -- Posting Details (Primary Source)
    j.id AS job_id,
    j.title AS job_title,
    j.description AS job_description, -- Added this field
    j.category,
    j.location,
    j.requirements AS job_requirements,
    j.funding_source,
    j.is_on_campus,
    j.salary_range,
    j.service_hours,
    j.deadline,
    j.is_active,
    j.created_at AS job_created_at,
    j.deleted_at AS job_deleted_at,

    -- Employer Details
    ep.user_id AS employer_id,
    ep.company_name,
    ep.website_url AS company_website,

    -- Application Details (LEFT JOINED)
    a.id AS application_id,
    a.student_id,
    a.status AS application_status,
    a.learning_objectives,
    a.notes AS student_notes, -- Student's "Cover Letter" text
    a.created_at AS applied_at,

    -- Student Details
    u.first_name || ' ' || u.last_name AS student_name,
    u.email AS student_email
FROM learningsystem.job_postings j
         JOIN learningsystem.employer_profiles ep ON j.employer_id = ep.user_id
         LEFT JOIN learningsystem.job_applications a ON a.job_id = j.id
         LEFT JOIN learningsystem.users u ON a.student_id = u.id;