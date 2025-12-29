package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.dto.EmployerJobViewDTO;
import com.ewu.career.entity.JobOversightView;
import com.ewu.career.entity.JobPosting;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.transaction.Transactional;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Stateless
@Named("JobPostingDao")
public class JobPostingDao {

    @Inject
    @Named("DefaultJpaDao")
    private JpaDao jpa;

    public List<JobOversightView> findPlacementsByStatus(String status, String category) {
        return jpa.getEntityManager()
                .createQuery(
                        "SELECT v FROM JobOversightView v WHERE v.category = :cat AND"
                                + " v.applicationStatus = :stat",
                        JobOversightView.class)
                .setParameter("cat", category)
                .setParameter("stat", status)
                .getResultList();
    }

    //    /** Retrieves DTOs from the internship view. */
    //    public List<InternshipOversightView> findPracticumsByStatus(String status, String
    // category) {
    //        String jpql =
    //                "SELECT v FROM InternshipOversightView v "
    //                        + "WHERE v.category = :cat AND v.applicationStatus = :stat "
    //                        + "ORDER BY v.appliedAt DESC";
    //
    //        return jpa.getEntityManager()
    //                .createQuery(jpql, InternshipOversightView.class)
    //                .setParameter("cat", category)
    //                .setParameter("stat", status)
    //                .getResultList();
    //    }

    public EmployerJobViewDTO getEmployerJobDetailView(UUID jobId, UUID employerId) {

        String sql =
                "SELECT j.id, j.title, j.description, j.requirements, j.category, j.location,"
                    + " j.salary_range, j.created_at, j.is_active, (SELECT COUNT(*) FROM"
                    + " learningsystem.job_applications a WHERE a.job_id = j.id) as app_count,"
                    + " j.funding_source, j.deadline FROM learningsystem.job_postings j WHERE j.id"
                    + " = :jid AND j.employer_id = :eid";

        Object[] row =
                (Object[])
                        jpa.getEntityManager()
                                .createNativeQuery(sql)
                                .setParameter("jid", jobId)
                                .setParameter("eid", employerId)
                                .getSingleResult();

        return new EmployerJobViewDTO(
                (UUID) row[0],
                (String) row[1],
                (String) row[2],
                (String) row[3],
                (String) row[4],
                (String) row[5],
                (String) row[6],
                ((java.sql.Timestamp) row[7]).toLocalDateTime(),
                (Boolean) row[8],
                ((Number) row[9]).longValue(),
                (String) row[10],
                ((java.sql.Date) row[11]).toLocalDate());
    }

    /** Retrieves a specific job posting by its unique ID. */
    public JobPosting find(UUID id) {
        return jpa.find(JobPosting.class, id);
    }

    /** Filters active job postings based on the student's funding eligibility. */
    public List<JobPosting> findEligibleJobs(boolean isWorkStudyEligible) {
        String query = "SELECT j FROM JobPosting j WHERE j.isActive = true ";
        if (!isWorkStudyEligible) {
            query += "AND j.fundingSource != 'WORK_STUDY'"; // Enforce RFP funding logic
        }
        return jpa.selectAll(query, JobPosting.class);
    }

    public List<JobOversightView> findAllPostings() {
        String query = "SELECT j FROM JobOversightView j WHERE j.isActive = true ";
        return jpa.selectAll(query, JobOversightView.class);
    }

    /**
     * Counts all job postings that are not yet active/approved. Maps to the "Pending Job Approvals"
     * KPI in the Command Center.
     */
    public long countPending() {
        return jpa.getEntityManager()
                .createQuery(
                        "SELECT COUNT(j) FROM JobPosting j WHERE j.isActive = false", Long.class)
                .getSingleResult();
    }

    public List<JobPosting> findByEmployer(UUID employerId) {
        String query = "SELECT j FROM JobPosting j WHERE j.employerId = :employerId";
        Map<String, Object> params = new HashMap<>();
        params.put("employerId", employerId);
        return jpa.selectAllWithParameters(query, JobPosting.class, params);
    }

    public JobPosting create(JobPosting entity) {
        return jpa.create(entity);
    }

    /** Updates an existing job posting. Used for editing job details or toggling active status. */
    public JobPosting update(JobPosting entity) {
        return jpa.update(entity);
    }

    /**
     * Soft deletes a job posting. This keeps the record in the DB so JobApplications remain linked.
     */
    @Transactional
    public void softDelete(UUID jobId) {
        jpa.getEntityManager()
                .createQuery(
                        "UPDATE JobPosting p SET p.isActive = false, p.deletedAt = :now WHERE p.id"
                                + " = :id")
                .setParameter("now", LocalDateTime.now())
                .setParameter("id", jobId)
                .executeUpdate();
    }

    public void delete(UUID id) {
        jpa.delete(JobPosting.class, id);
    }
}
