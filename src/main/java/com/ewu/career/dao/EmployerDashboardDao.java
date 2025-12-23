package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.dto.EmployerDashboardSummary;
import com.ewu.career.dto.JobPipelineDTO;
import com.ewu.career.dto.JobPostingListDTO;
import com.ewu.career.dto.RecentActivityDTO;
import com.ewu.career.util.TimeFormattingUtils;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

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

        return new EmployerDashboardSummary(
                activeJobs, totalPending, companyName, pipelines, activity);
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
        // We use a Native Query here to join Applications and Users to create a readable message
        List<Object[]> rows =
                jpa.getEntityManager()
                        .createNativeQuery(
                                "SELECT u.first_name || ' ' || u.last_name || ' applied to ' ||"
                                    + " j.title as message, 'APPLICATION' as type, a.created_at as"
                                    + " timestamp FROM learningsystem.job_applications a JOIN"
                                    + " learningsystem.job_postings j ON a.job_id = j.id JOIN"
                                    + " learningsystem.users u ON a.student_id = u.id WHERE"
                                    + " j.employer_id = :eid ORDER BY a.created_at DESC LIMIT 5")
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
                                    TimeFormattingUtils.formatTimeAgo(
                                            ts) // <--- Utility applied here
                                    );
                        })
                .toList();
    }
}
