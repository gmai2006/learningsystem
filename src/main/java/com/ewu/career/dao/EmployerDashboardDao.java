package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.dto.*;
import com.ewu.career.util.TimeFormattingUtils;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import javax.transaction.Transactional;

@Stateless
@Named("EmployerDashboardDao")
public class EmployerDashboardDao {

    @Inject
    @Named("DefaultJpaDao")
    private JpaDao jpa;

    public List<JobPostingListDTO> getEmployerJobPostings(UUID employerId) {
        String sql =
                "SELECT j.id, j.title, j.category, j.created_at, j.is_active, (SELECT COUNT(*) FROM"
                    + " learningsystem.job_applications a WHERE a.job_id = j.id) as app_count FROM"
                    + " learningsystem.job_postings j WHERE j.employer_id = :eid ORDER BY"
                    + " j.created_at DESC";

        List<Object[]> rows =
                jpa.getEntityManager()
                        .createNativeQuery(sql)
                        .setParameter("eid", employerId)
                        .getResultList();

        return rows.stream()
                .map(
                        row ->
                                new JobPostingListDTO(
                                        (UUID) row[0],
                                        (String) row[1],
                                        (String) row[2],
                                        ((java.sql.Timestamp) row[3]).toLocalDateTime(),
                                        (Boolean) row[4],
                                        ((Number) row[5]).longValue()))
                .toList();
    }

    public EmployerDashboardSummary getEmployerSummary(UUID employerId) {

        // 1. Get Company Name (assuming it's stored in a company or user profile table)
        String companyName =
                (String)
                        jpa.getEntityManager()
                                .createNativeQuery(
                                        "SELECT company_name FROM learningsystem.employer_profiles"
                                                + " WHERE user_id = :eid")
                                .setParameter("eid", employerId)
                                .getSingleResult();

        // 2. Count Active Job Postings (excluding soft-deleted)
        Long activeJobs =
                jpa.getEntityManager()
                        .createQuery(
                                "SELECT COUNT(j) FROM JobPosting j WHERE j.employerId = :eid AND"
                                        + " j.isActive = true",
                                Long.class)
                        .setParameter("eid", employerId)
                        .getSingleResult();

        // 3. Count Total Pending Applicants across all jobs
        Long totalPending =
                jpa.getEntityManager()
                        .createQuery(
                                "SELECT COUNT(a) FROM JobApplication a JOIN JobPosting j ON a.jobId"
                                    + " = j.id WHERE j.employerId = :eid AND a.status = 'PENDING'",
                                Long.class)
                        .setParameter("eid", employerId)
                        .getSingleResult();

        // 4. Fetch Active Pipelines (Funnel Data)
        // Using the logic derived earlier to count apps per stage
        List<JobPipelineDTO> pipelines = getActivePipelines(employerId);

        // 5. Fetch Recent Activity Feed
        List<RecentActivityDTO> activity = fetchRecentActivity(employerId);

        Map<String, Object> hiringStats = getHiringStats(employerId);

        return new EmployerDashboardSummary(
                activeJobs,
                totalPending,
                companyName,
                (Integer) hiringStats.get("totalPlacements"),
                (Long) hiringStats.get("avgDaysToHire"),
                pipelines,
                activity);
    }

    public Map<String, Object> getHiringStats(UUID employerId) {
        String sql =
                "SELECT COUNT(CASE WHEN a.status = 'HIRED' THEN 1 END) as total_placements,"
                        + " AVG(CASE WHEN a.status = 'HIRED' THEN EXTRACT(DAY FROM (a.updated_at -"
                        + " j.created_at)) END) as avg_days FROM learningsystem.job_postings j LEFT"
                        + " JOIN learningsystem.job_applications a ON j.id = a.job_id WHERE"
                        + " j.employer_id = :eid";

        Object[] row =
                (Object[])
                        jpa.getEntityManager()
                                .createNativeQuery(sql)
                                .setParameter("eid", employerId)
                                .getSingleResult();

        return Map.of(
                "totalPlacements", row[0] != null ? ((Number) row[0]).intValue() : 0,
                "avgDaysToHire", row[1] != null ? Math.round(((Number) row[1]).doubleValue()) : 0);
    }

    public List<JobPipelineDTO> getActivePipelines(UUID employerId) {
        String sql =
                "SELECT j.id, j.title, SUM(CASE WHEN a.status = 'PENDING' THEN 1 ELSE 0 END) as"
                    + " pending, SUM(CASE WHEN a.status = 'INTERVIEW_SCHEDULED' THEN 1 ELSE 0 END)"
                    + " as interview, SUM(CASE WHEN a.status = 'OFFER_EXTENDED' THEN 1 ELSE 0 END)"
                    + " as offer, CAST(EXTRACT(DAY FROM (NOW() - j.created_at)) AS int) as days_ago"
                    + " "
                        + // CHANGED HERE
                        "FROM learningsystem.job_postings j "
                        + "LEFT JOIN learningsystem.job_applications a ON j.id = a.job_id "
                        + "WHERE j.employer_id = :eid AND j.is_active = true "
                        + "GROUP BY j.id, j.title, j.created_at";

        return jpa.getEntityManager()
                .createNativeQuery(sql, JobPipelineDTO.class)
                .setParameter("eid", employerId)
                .getResultList();
    }

    private List<RecentActivityDTO> fetchRecentActivity(UUID employerId) {
        // We combine application events and posting events into one unified timeline
        String sql =
                "SELECT message, type, timestamp FROM (  SELECT u.first_name || ' ' || u.last_name"
                    + " || ' applied to ' || j.title as message,   'APPLICATION' as type,"
                    + " a.created_at as timestamp   FROM learningsystem.job_applications a   JOIN"
                    + " learningsystem.job_postings j ON a.job_id = j.id   JOIN"
                    + " learningsystem.users u ON a.student_id = u.id   WHERE j.employer_id = :eid "
                    + "  UNION ALL   SELECT 'You posted a new position: ' || title as message,  "
                    + " 'JOB_POSTED' as type, created_at as timestamp   FROM"
                    + " learningsystem.job_postings   WHERE employer_id = :eid) activity ORDER BY"
                    + " timestamp DESC LIMIT 5";

        List<Object[]> rows =
                jpa.getEntityManager()
                        .createNativeQuery(sql)
                        .setParameter("eid", employerId)
                        .getResultList();

        return rows.stream()
                .map(
                        row -> {
                            LocalDateTime ts = ((java.sql.Timestamp) row[2]).toLocalDateTime();
                            return new RecentActivityDTO(
                                    (String) row[0],
                                    (String) row[1],
                                    ts,
                                    TimeFormattingUtils.formatTimeAgo(ts));
                        })
                .toList();
    }

    /** Retrieves the list of applicants for an employer, optionally filtered by job. */
    public List<EmployerApplicantDTO> getApplicants(UUID employerId, UUID jobId) {
        // Base SQL with schema-qualified table names
        StringBuilder sql =
                new StringBuilder(
                        "SELECT a.id as application_id, u.id as student_id, u.first_name || ' ' ||"
                            + " u.last_name as student_name, u.email, sp.major, sp.gpa, j.title as"
                            + " job_title, a.status, a.created_at, sp.profile_picture_base64 FROM"
                            + " learningsystem.job_applications a JOIN learningsystem.job_postings"
                            + " j ON a.job_id = j.id JOIN learningsystem.users u ON a.student_id ="
                            + " u.id LEFT JOIN learningsystem.student_profiles sp ON u.id ="
                            + " sp.user_id WHERE j.employer_id = :eid ");

        // Conditional filtering for a specific job
        if (jobId != null) {
            sql.append("AND j.id = :jid ");
        }

        sql.append("ORDER BY a.created_at DESC");

        var query =
                jpa.getEntityManager()
                        .createNativeQuery(sql.toString())
                        .setParameter("eid", employerId);

        if (jobId != null) {
            query.setParameter("jid", jobId);
        }

        List<Object[]> rows = query.getResultList();

        return rows.stream()
                .map(
                        row ->
                                new EmployerApplicantDTO(
                                        (UUID) row[0], // applicationId
                                        (UUID) row[1], // studentId
                                        (String) row[2], // studentName
                                        (String) row[3], // email
                                        (String) row[4], // major
                                        row[5] != null
                                                ? ((Number) row[5]).doubleValue()
                                                : null, // gpa
                                        (String) row[6], // jobTitle
                                        (String) row[7], // status
                                        ((java.sql.Timestamp) row[8])
                                                .toLocalDateTime(), // appliedAt
                                        TimeFormattingUtils.formatTimeAgo(
                                                ((java.sql.Timestamp) row[8])
                                                        .toLocalDateTime()), // timeAgo
                                        (String) row[9] // profilePicture
                                        ))
                .toList();
    }

    /** Updates an application status after verifying employer ownership. */
    @Transactional
    public boolean updateApplicationStatus(UUID employerId, UUID applicationId, String newStatus) {
        // We use a subquery check to ensure the employer owns the job associated with this
        // application
        String sql =
                "UPDATE learningsystem.job_applications a "
                        + "SET status = :status "
                        + "WHERE a.id = :aid "
                        + "AND EXISTS ("
                        + "  SELECT 1 FROM learningsystem.job_postings j "
                        + "  WHERE j.id = a.job_id AND j.employer_id = :eid"
                        + ")";

        int updatedRows =
                jpa.getEntityManager()
                        .createNativeQuery(sql)
                        .setParameter("status", newStatus)
                        .setParameter("aid", applicationId)
                        .setParameter("eid", employerId)
                        .executeUpdate();

        return updatedRows > 0;
    }

    public ApplicantNotificationDetails getApplicantNotificationDetails(UUID applicationId) {
        String sql =
                "SELECT u.email, u.first_name, j.title, ep.company_name "
                        + "FROM learningsystem.job_applications a "
                        + "JOIN learningsystem.users u ON a.student_id = u.id "
                        + "JOIN learningsystem.job_postings j ON a.job_id = j.id "
                        + "JOIN learningsystem.employer_profiles ep ON j.employer_id = ep.user_id "
                        + "WHERE a.id = :aid";

        Object[] row =
                (Object[])
                        jpa.getEntityManager()
                                .createNativeQuery(sql)
                                .setParameter("aid", applicationId)
                                .getSingleResult();

        return new ApplicantNotificationDetails(
                (String) row[0], (String) row[1], (String) row[2], (String) row[3]);
    }

    public EmployerCandidateProfileDTO getFullCandidateProfile(
            UUID employerId, UUID applicationId) {
        String sql =
                "SELECT a.id, u.first_name || ' ' || u.last_name as student_name, u.email, "
                        + "sp.major, sp.gpa, sp.graduation_year, sp.bio, sp.resume_url, "
                        + "sp.portfolio_url, sp.linkedin_url, sp.github_url, "
                        + "sp.profile_picture_base64, a.status, j.title, a.student_id "
                        + "FROM learningsystem.job_applications a "
                        + "JOIN learningsystem.users u ON a.student_id = u.id "
                        + "JOIN learningsystem.student_profiles sp ON u.id = sp.user_id "
                        + "JOIN learningsystem.job_postings j ON a.job_id = j.id "
                        + "WHERE a.id = :aid AND j.employer_id = :eid";

        Object[] row =
                (Object[])
                        jpa.getEntityManager()
                                .createNativeQuery(sql)
                                .setParameter("aid", applicationId)
                                .setParameter("eid", employerId)
                                .getSingleResult();

        return new EmployerCandidateProfileDTO(
                (UUID) row[0], // applicationId
                (String) row[1], // studentName
                (String) row[2], // email
                (String) row[3], // major
                row[4] != null ? ((Number) row[4]).doubleValue() : null, // gpa
                row[5] != null ? ((Number) row[5]).intValue() : null, // graduationYear
                (String) row[6], // bio
                (String) row[7], // resumeUrl
                (String) row[8], // portfolioUrl
                (String) row[9], // linkedinUrl
                (String) row[10], // githubUrl
                (String) row[11], // profilePicture
                (String) row[12], // status
                (String) row[13], // jobTitle
                (UUID) row[14]);
    }

    public String getResumeUrlIfAuthorized(UUID employerId, UUID applicationId) {
        String sql =
                "SELECT sp.resume_url "
                        + "FROM learningsystem.job_applications a "
                        + "JOIN learningsystem.job_postings j ON a.job_id = j.id "
                        + "JOIN learningsystem.student_profiles sp ON a.student_id = sp.user_id "
                        + "WHERE a.id = :aid AND j.employer_id = :eid";

        try {
            return (String)
                    jpa.getEntityManager()
                            .createNativeQuery(sql)
                            .setParameter("aid", applicationId)
                            .setParameter("eid", employerId)
                            .getSingleResult();
        } catch (jakarta.persistence.NoResultException e) {
            return null;
        }
    }

    @Transactional
    public void logNotification(
            UUID applicationId, String email, String subject, String body, String type) {
        String sql =
                "INSERT INTO learningsystem.notification_logs (application_id, recipient_email,"
                        + " subject, content, notification_type, sent_at) VALUES (:aid, :email,"
                        + " :subject, :body, :type, NOW())";

        jpa.getEntityManager()
                .createNativeQuery(sql)
                .setParameter("aid", applicationId)
                .setParameter("email", email)
                .setParameter("subject", subject)
                .setParameter("body", body)
                .setParameter("type", type)
                .executeUpdate();
    }

    /** Fetches all upcoming interviews for jobs owned by a specific employer. */
    public List<EmployerInterviewDTO> getUpcomingInterviews(UUID employerId) {
        String sql =
                "SELECT i.id, i.application_id, u.first_name || ' ' || u.last_name as student_name,"
                    + " sp.profile_picture_base64, j.title as job_title, i.scheduled_at,"
                    + " i.is_virtual, i.meeting_url, i.location_notes FROM"
                    + " learningsystem.interviews i JOIN learningsystem.job_applications a ON"
                    + " i.application_id = a.id JOIN learningsystem.users u ON a.student_id = u.id"
                    + " JOIN learningsystem.student_profiles sp ON u.id = sp.user_id JOIN"
                    + " learningsystem.job_postings j ON a.job_id = j.id WHERE j.employer_id = :eid"
                    + " AND i.scheduled_at >= NOW() AND i.status != 'CANCELLED' ORDER BY"
                    + " i.scheduled_at ASC";

        @SuppressWarnings("unchecked")
        List<Object[]> rows =
                jpa.getEntityManager()
                        .createNativeQuery(sql)
                        .setParameter("eid", employerId)
                        .getResultList();

        return rows.stream()
                .map(
                        row ->
                                new EmployerInterviewDTO(
                                        (UUID) row[0], // id
                                        (UUID) row[1], // applicationId
                                        (String) row[2], // studentName
                                        (String) row[3], // studentProfilePicture
                                        (String) row[4], // jobTitle
                                        ((java.sql.Timestamp) row[5])
                                                .toLocalDateTime(), // scheduledAt (Converted from
                                        // SQL)
                                        (Boolean) row[6], // isVirtual
                                        (String) row[7], // meetingUrl
                                        (String) row[8] // locationNotes
                                        ))
                .toList();
    }

    /** Updates the interview time after verifying employer ownership of the job. */
    @Transactional
    public boolean rescheduleInterview(UUID employerId, UUID interviewId, LocalDateTime newTime) {
        String sql =
                "UPDATE learningsystem.interviews i "
                        + "SET scheduled_at = :newTime, status = 'RESCHEDULED', updated_at = NOW() "
                        + "FROM learningsystem.job_applications a "
                        + "JOIN learningsystem.job_postings j ON a.job_id = j.id "
                        + "WHERE i.application_id = a.id AND j.employer_id = :eid AND i.id = :iid";

        int rowsAffected =
                jpa.getEntityManager()
                        .createNativeQuery(sql)
                        .setParameter("newTime", newTime)
                        .setParameter("eid", employerId)
                        .setParameter("iid", interviewId)
                        .executeUpdate();

        return rowsAffected > 0;
    }
}
