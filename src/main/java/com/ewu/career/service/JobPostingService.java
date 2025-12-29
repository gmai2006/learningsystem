package com.ewu.career.service;

import com.ewu.career.dao.JobPostingDao;
import com.ewu.career.dao.StudentProfileDao;
import com.ewu.career.dao.SystemConfigDao;
import com.ewu.career.dto.StudentProfileDTO;
import com.ewu.career.entity.*;
import com.ewu.career.interceptor.AuditAction;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@AuditAction
@Stateless
@Named("JobPostingService")
public class JobPostingService {

    /** Roles authorized to create and manage job postings. */
    private static final Set<String> POSTING_ROLES = Set.of("STAFF", "EMPLOYER");

    @Inject private JobPostingDao jobPostingDao;

    @Inject private StudentProfileDao studentProfileDao;

    @Inject private SystemConfigDao configDao;

    public List<JobOversightView> findPracticumsByStatus(String status) {
        return jobPostingDao.findPlacementsByStatus(status, "INTERNSHIP");
    }

    /**
     * Retrieves job postings filtered by student eligibility. If the actor is a student, the list
     * is restricted based on their Banner-synced status.
     *
     * @param actor The student browsing the job board.
     */
    public List<JobPosting> getJobsForStudent(User actor) {
        // Non-students (Staff/Employers) see all standard jobs by default
        if (!"STUDENT".equals(actor.getRole().name())) {
            return jobPostingDao.findEligibleJobs(false);
        }

        // Fetch student's academic profile for Work Study status
        StudentProfileDTO profile = studentProfileDao.findByUserId(actor.getId());
        boolean isWorkStudyEligible = (profile != null && profile.workStudyEligible());

        return jobPostingDao.findEligibleJobs(isWorkStudyEligible);
    }

    /**
     * Retrieves job postings filtered by student eligibility. If the actor is a student, the list
     * is restricted based on their Banner-synced status.
     *
     * @param actor The student browsing the job board.
     */
    public List<JobOversightView> findAllPostings(User actor) {
        // Non-students (Staff/Employers) see all standard jobs by default
        if ("STUDENT".equals(actor.getRole().name())) {
            return Collections.emptyList();
        }
        return jobPostingDao.findAllPostings();
    }

    /**
     * Creates a new job posting. Enforces RBAC to ensure only approved Employers or Staff can post.
     */
    public JobPosting createJob(User actor, JobPosting job) {
        if (actor == null || !POSTING_ROLES.contains(actor.getRole().name())) {
            throw new SecurityException("Forbidden: Unauthorized to post jobs.");
        }

        // Set employer ID to the actor if they are an Employer user
        if ("EMPLOYER".equals(actor.getRole().name())) {
            job.setEmployerId(actor.getId());
        }

        boolean approvalNeeded = configDao.getBooleanValue("JOB_APPROVAL_REQUIRED");
        if (approvalNeeded && actor.getRole() == UserRole.EMPLOYER) {
            job.setIsActive(false); // Force pending status for vetting
        } else job.setIsActive(true);
        return jobPostingDao.create(job);
    }

    /**
     * Updates an existing job posting. Verified against the original employer or Staff oversight.
     */
    public JobPosting updateJob(User actor, JobPosting job) {
        JobPosting existing = jobPostingDao.find(job.getId());

        boolean isOwner = actor.getId().equals(existing.getEmployerId());
        boolean isStaff = "STAFF".equals(actor.getRole().name());

        if (!isOwner && !isStaff) {
            throw new SecurityException(
                    "Forbidden: You do not have permission to edit this posting.");
        }

        return jobPostingDao.update(job);
    }

    /** Toggles job visibility (Active/Inactive). */
    public void setJobStatus(User actor, UUID jobId, boolean isActive) {
        JobPosting existing = jobPostingDao.find(jobId);

        boolean isOwner = actor.getId().equals(existing.getEmployerId());
        boolean isStaff = "STAFF".equals(actor.getRole().name());

        if (!isOwner && !isStaff) {
            throw new SecurityException(
                    "Forbidden: You do not have permission to edit this posting.");
        }

        JobPosting job = jobPostingDao.find(jobId);
        if (job != null) {
            job.setIsActive(isActive);
            updateJob(actor, job);
        }
    }
}
