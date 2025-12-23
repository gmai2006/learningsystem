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
    sp.github_url
FROM learningsystem.users u
JOIN learningsystem.student_profiles sp ON u.id = sp.user_id;