package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.dto.JobApplicationDTO;
import com.ewu.career.dto.JobFilters;
import com.ewu.career.dto.JobPostingDTO;
import com.ewu.career.entity.JobApplication;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.transaction.Transactional;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class JobApplicationDao {

    @Inject
    @Named("DefaultJpaDao")
    private JpaDao jpa;

    @Transactional
    public void withdrawApplication(UUID applicationId, UUID studentId) {
        // We use a query that includes studentId for security (prevents ID tampering)
        int updatedRows =
                jpa.getEntityManager()
                        .createQuery(
                                "UPDATE JobApplication a SET a.status = 'WITHDRAWN', a.updatedAt ="
                                        + " :now WHERE a.id = :appId AND a.studentId = :sid AND"
                                        + " a.status = 'PENDING'")
                        .setParameter("now", LocalDateTime.now())
                        .setParameter("appId", applicationId)
                        .setParameter("sid", studentId)
                        .executeUpdate();

        if (updatedRows == 0) {
            throw new IllegalStateException(
                    "Application cannot be withdrawn (it may have already been processed or does"
                            + " not belong to you).");
        }
    }

    /**
     * Fetches applications for a specific student, joining with JobPosting to provide the actual
     * titles and locations.
     */
    public List<JobApplicationDTO> findByStudentId(UUID studentId) {
        String jpql =
                "SELECT new com.ewu.career.dto.JobApplicationDTO("
                        + "a.id, a.jobId, p.title, p.location, a.status, a.notes, "
                        + "a.createdAt, p.isActive, p.description, p.fundingSource) "
                        + // Map the active status here
                        "FROM JobApplication a "
                        + "JOIN JobPosting p ON a.jobId = p.id "
                        + "WHERE a.studentId = :sid "
                        + "ORDER BY a.createdAt DESC";

        return jpa.getEntityManager()
                .createQuery(jpql, JobApplicationDTO.class)
                .setParameter("sid", studentId)
                .getResultList();
    }

    @Transactional
    public List<JobPostingDTO> getStudentJobView(UUID studentId, JobFilters filters) {
        // 1. Base Query with the Constructor Expression
        // The subquery (SELECT count(a) > 0...) maps to the 'isApplied' boolean in the DTO
        StringBuilder jpql =
                new StringBuilder(
                        "SELECT new com.ewu.career.dto.JobPostingDTO(p.id, p.title, p.description,"
                            + " p.location, p.fundingSource, p.deadline, p.createdAt, p.isOnCampus,"
                            + " (SELECT count(a) > 0 FROM JobApplication a WHERE a.jobId = p.id AND"
                            + " a.studentId = :sid)) FROM JobPosting p WHERE p.isActive = true AND"
                            + " p.deletedAt IS NULL ");

        // 2. Dynamically Append Filters
        if (filters.getSearch() != null && !filters.getSearch().isEmpty()) {
            jpql.append(
                    "AND (lower(p.title) LIKE lower(:search) OR lower(p.description) LIKE"
                            + " lower(:search)) ");
        }
        if (filters.getFundingSource() != null && !filters.getFundingSource().isEmpty()) {
            jpql.append("AND p.fundingSource = :funding ");
        }
        if (filters.getOnCampus() != null) {
            jpql.append("AND p.isOnCampus = :onCampus ");
        }

        // 3. Create Query and Bind Parameters
        var query =
                jpa.getEntityManager()
                        .createQuery(jpql.toString(), JobPostingDTO.class)
                        .setParameter("sid", studentId);

        if (filters.getSearch() != null && !filters.getSearch().isEmpty()) {
            query.setParameter("search", "%" + filters.getSearch() + "%");
        }
        if (filters.getFundingSource() != null && !filters.getFundingSource().isEmpty()) {
            query.setParameter("funding", filters.getFundingSource());
        }
        if (filters.getOnCampus() != null) {
            query.setParameter("onCampus", filters.getOnCampus());
        }

        return query.getResultList();
    }

    @Transactional
    public JobApplication submitApplication(UUID studentId, UUID jobId, String notes) {
        // 1. Business Logic check (keep this to prevent duplicate logic errors)
        if (exists(studentId, jobId)) {
            throw new IllegalStateException("Application already exists.");
        }

        // 2. Build the entity
        JobApplication app = new JobApplication();

        // NOTE: If you use @GeneratedValue(strategy = GenerationType.AUTO)
        // in the entity, do NOT manually set the ID here.
        // app.setId(UUID.randomUUID()); <--- REMOVE OR COMMENT THIS OUT

        app.setStudentId(studentId);
        app.setJobId(jobId);
        app.setNotes(notes);
        app.setStatus("PENDING");

        // 3. Use MERGE instead of PERSIST
        // merge() is smarter about detached vs transient states.
        return jpa.getEntityManager().merge(app);
    }

    /**
     * Persists a new application. The @PrePersist in the entity handles timestamps automatically.
     */
    @Transactional
    public JobApplication save(JobApplication application) {
        if (application.getId() == null) {
            application.setId(UUID.randomUUID());
            jpa.create(application);
            return application;
        } else {
            return jpa.update(application);
        }
    }

    /** Updates the status of an application (e.g., from PENDING to REVIEWING). */
    @Transactional
    public void updateStatus(UUID applicationId, String newStatus) {
        jpa.getEntityManager()
                .createQuery("UPDATE JobApplication a SET a.status = :status WHERE a.id = :id")
                .setParameter("status", newStatus)
                .setParameter("id", applicationId)
                .executeUpdate();
    }

    /**
     * Finds all applications for a specific job posting. Used by Employers/Staff to review
     * candidates.
     */
    public List<JobApplication> findByJobId(UUID jobId) {
        return jpa.getEntityManager()
                .createQuery(
                        "SELECT a FROM JobApplication a WHERE a.jobId = :jid ORDER BY a.createdAt"
                                + " ASC",
                        JobApplication.class)
                .setParameter("jid", jobId)
                .getResultList();
    }

    /** Checks if a student has already applied to a specific job. */
    public boolean exists(UUID studentId, UUID jobId) {
        Long count =
                jpa.getEntityManager()
                        .createQuery(
                                "SELECT COUNT(a) FROM JobApplication a WHERE a.studentId = :sid AND"
                                        + " a.jobId = :jid",
                                Long.class)
                        .setParameter("sid", studentId)
                        .setParameter("jid", jobId)
                        .getSingleResult();
        return count > 0;
    }
}
