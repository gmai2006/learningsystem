package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.entity.JobPosting;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
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

    public List<JobPosting> findAllPostings() {
        String query = "SELECT j FROM JobPosting j WHERE j.isActive = true ";
        return jpa.selectAll(query, JobPosting.class);
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

    public void delete(UUID id) {
        jpa.delete(JobPosting.class, id);
    }
}
