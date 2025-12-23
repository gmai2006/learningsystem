SELECT j.id, j.title, SUM(CASE WHEN a.status = 'PENDING' THEN 1 ELSE 0 END) as
                     pending, SUM(CASE WHEN a.status = 'INTERVIEW_SCHEDULED' THEN 1 ELSE 0 END)
                     as interview, SUM(CASE WHEN a.status = 'OFFER_EXTENDED' THEN 1 ELSE 0 END)
                     as offer, EXTRACT(DAY FROM (NOW() - j.created_at))::int as days_ago FROM
                     learningsystem.job_postings j LEFT JOIN learningsystem.job_applications a
                     ON j.id = a.job_id WHERE j.employer_id = :eid AND j.is_active = true GROUP BY
                     j.id, j.title, j.created_at