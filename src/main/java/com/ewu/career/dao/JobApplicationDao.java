package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.dto.JobFilters;
import com.ewu.career.entity.JobApplication;
import com.ewu.career.entity.JobOversightView;
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
     * Fetches applications for a specific student using the unified JobOversightView. This provides
     * rich data including company details and learning objectives without manual DTO mapping.
     */
    public List<JobOversightView> findByStudentId(UUID studentId) {
        // We select from the View where the studentId matches.
        // Because the view is a LEFT JOIN, filtering by studentId effectively
        // returns only the jobs that THIS specific student has applied for.
        String jpql =
                "SELECT v FROM JobOversightView v "
                        + "WHERE v.studentId = :sid "
                        + "ORDER BY v.appliedAt DESC";

        return jpa.getEntityManager()
                .createQuery(jpql, JobOversightView.class)
                .setParameter("sid", studentId)
                .getResultList();
    }

    public List<JobOversightView> getStudentJobView(UUID studentId, JobFilters filters) {
        StringBuilder jpql =
                new StringBuilder(
                        "SELECT v FROM JobOversightView v "
                                + "WHERE v.isActive = true AND v.jobDeletedAt IS NULL ");

        // 2. Dynamically Append Filters
        if (filters.getSearch() != null && !filters.getSearch().isEmpty()) {
            jpql.append(
                    "AND (lower(v.jobTitle) LIKE lower(:search) "
                            + "OR lower(v.companyName) LIKE lower(:search) "
                            + "OR lower(v.location) LIKE lower(:search)) ");
        }

        if (filters.getFundingSource() != null && !filters.getFundingSource().isEmpty()) {
            jpql.append("AND v.fundingSource = :funding ");
        }

        if (filters.getOnCampus() != null) {
            jpql.append("AND v.isOnCampus = :onCampus ");
        }

        // 3. Create Query and Bind Parameters
        var query = jpa.getEntityManager().createQuery(jpql.toString(), JobOversightView.class);

        // 4. Parameter Binding
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

    public List<JobOversightView> getStudentApplicationView(UUID studentId, JobFilters filters) {
        // 1. Base Query using the Immutable Entity
        StringBuilder jpql =
                new StringBuilder("SELECT v FROM JobOversightView v WHERE v.studentId = :sid ");

        // 2. Dynamically Append Filters based on the View's fields
        if (filters.getSearch() != null && !filters.getSearch().isEmpty()) {
            jpql.append(
                    "AND (lower(v.jobTitle) LIKE lower(:search) "
                            + "OR lower(v.companyName) LIKE lower(:search)) ");
        }

        if (filters.getFundingSource() != null && !filters.getFundingSource().isEmpty()) {
            jpql.append("AND v.fundingSource = :funding ");
        }

        if (filters.getOnCampus() != null) {
            jpql.append("AND v.isOnCampus = :onCampus ");
        }

        // Sort by most recent application
        jpql.append("ORDER BY v.appliedAt DESC");

        // 3. Create Query and Bind Parameters
        var query =
                jpa.getEntityManager()
                        .createQuery(jpql.toString(), JobOversightView.class)
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

    public List<JobOversightView> getStudentVolunteerJobView(UUID studentId, JobFilters filters) {
        // 1. Query the JobOversightView entity directly.
        // Logic: Filter by 'Volunteer' category and ensure the student sees
        // their specific application record OR the vacant posting (studentId IS NULL).
        StringBuilder jpql =
                new StringBuilder(
                        "SELECT v FROM JobOversightView v "
                                + "WHERE v.category = 'Volunteer' "
                                + "AND v.isActive = true "
                                + "AND v.jobDeletedAt IS NULL "
                                + "AND (v.studentId = :sid OR v.studentId IS NULL) ");

        // 2. Dynamically Append Filters
        if (filters.getSearch() != null && !filters.getSearch().isEmpty()) {
            jpql.append(
                    "AND (lower(v.jobTitle) LIKE lower(:search) "
                            + "OR lower(v.companyName) LIKE lower(:search) "
                            + "OR lower(v.location) LIKE lower(:search)) ");
        }

        if (filters.getFundingSource() != null && !filters.getFundingSource().isEmpty()) {
            jpql.append("AND v.fundingSource = :funding ");
        }

        if (filters.getOnCampus() != null) {
            jpql.append("AND v.isOnCampus = :onCampus ");
        }

        // 3. Create Query and Bind Parameters
        var query =
                jpa.getEntityManager()
                        .createQuery(jpql.toString(), JobOversightView.class)
                        .setParameter("sid", studentId);

        // 4. Parameter Binding
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
        final JobApplication application = jpa.find(JobApplication.class, applicationId);
        application.setStatus(newStatus);
        jpa.update(application);
    }

    /**
     * Finds all applications for a specific job posting. Used by Employers/Staff to review
     * candidates.
     */
    public List<JobOversightView> findByJobId(UUID jobId) {
        return jpa.getEntityManager()
                .createQuery(
                        "SELECT a FROM JobOversightView a WHERE a.jobId = :jid ORDER BY a.createdAt"
                                + " ASC",
                        JobOversightView.class)
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
