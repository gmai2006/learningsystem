package com.ewu.career.service;

import com.ewu.career.dao.JobPostingDao;
import com.ewu.career.dao.StudentProfileDao;
import com.ewu.career.dto.StudentProfileDTO;
import com.ewu.career.entity.JobPosting;
import com.ewu.career.entity.User;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import java.util.List;

@Stateless
@Named("CareerJobService")
public class CareerJobService {

    @Inject private JobPostingDao jobDao;
    @Inject private StudentProfileDao profileDao;

    /** Finds jobs based on student eligibility status. */
    public List<JobPosting> findJobsForStudent(User actor) {
        if (!actor.getRole().name().equals("STUDENT")) {
            return jobDao.findEligibleJobs(false); // Default to non-work study for others
        }

        StudentProfileDTO profile = profileDao.findByUserId(actor.getId());
        boolean isEligible = (profile != null && profile.workStudyEligible());

        return jobDao.findEligibleJobs(isEligible);
    }

    public JobPosting createJob(User actor, JobPosting job) {
        if (!actor.getRole().name().equals("EMPLOYER") && !actor.getRole().name().equals("STAFF")) {
            throw new SecurityException("Forbidden: Only Employers or Staff can post jobs");
        }
        return jobDao.create(job);
    }
}
