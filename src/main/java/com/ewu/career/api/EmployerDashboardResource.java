package com.ewu.career.api;

import com.ewu.career.api.security.AuthContext;
import com.ewu.career.dao.EmployerDashboardDao;
import com.ewu.career.dao.JobPostingDao;
import com.ewu.career.dto.*;
import com.ewu.career.entity.JobPosting;
import com.ewu.career.entity.User;
import com.ewu.career.entity.UserRole;
import com.ewu.career.service.EmailService;
import com.ewu.career.service.JobPostingService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.io.File;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Path("/employer/dashboard")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class EmployerDashboardResource {

    @Inject private EmployerDashboardDao dashboardDao;

    @Inject private JobPostingDao jobPostingDao;

    @Inject private AuthContext authContext;

    @Inject private EmailService emailService;

    @Inject private JobPostingService jobPostingService;

    /**
     * Retrieves a unified summary for the Employer Dashboard. Includes job counts, applicant
     * counts, pipeline funnels, and recent activity.
     */
    @GET
    @Path("/summary")
    public Response getDashboardSummary() {
        User actor = authContext.getActor();
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }
        // Role-based security check (Staff/Faculty only)
        if (actor.getRole() != UserRole.EMPLOYER) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Access denied: Insufficient privileges for global oversight.")
                    .build();
        }

        try {
            EmployerDashboardSummary summary = dashboardDao.getEmployerSummary(actor.getId());
            return Response.ok(summary).build();
        } catch (Exception e) {
            // Log error and return a 500 if something goes wrong in the aggregation
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("Failed to load dashboard statistics.")
                    .build();
        }
    }

    @GET
    @Path("/interviews")
    public Response getInterviews() {
        UUID employerId = authContext.getActor().getId();
        List<EmployerInterviewDTO> interviews = dashboardDao.getUpcomingInterviews(employerId);
        return Response.ok(interviews).build();
    }

    @PATCH
    @Path("/interviews/{interviewId}/reschedule")
    public Response reschedule(
            @PathParam("interviewId") UUID interviewId, RescheduleInterviewDTO dto) {

        UUID employerId = authContext.getActor().getId();
        boolean success =
                dashboardDao.rescheduleInterview(employerId, interviewId, dto.newScheduledAt());

        if (success) {
            return Response.ok("Interview rescheduled successfully.").build();
        }
        return Response.status(Response.Status.FORBIDDEN)
                .entity("Unauthorized to reschedule this interview.")
                .build();
    }

    @GET
    @Path("/my-postings")
    public Response getMyJobs() {
        User actor = authContext.getActor();
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }
        // Role-based security check (Staff/Faculty only)
        if (actor.getRole() != UserRole.EMPLOYER) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Access denied: Insufficient privileges for global oversight.")
                    .build();
        }

        UUID employerId = authContext.getActor().getId();
        return Response.ok(dashboardDao.getEmployerJobPostings(employerId)).build();
    }

    @GET
    @Path("/applicants")
    public Response getApplicants(@QueryParam("jobId") UUID jobId) {
        User actor = authContext.getActor();
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }
        // Role-based security check (Staff/Faculty only)
        if (actor.getRole() != UserRole.EMPLOYER) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Access denied: Insufficient privileges for global oversight.")
                    .build();
        }

        UUID employerId = authContext.getActor().getId();

        try {
            // 2. Delegate to the centralized DAO
            List<EmployerApplicantDTO> applicants = dashboardDao.getApplicants(employerId, jobId);

            return Response.ok(applicants).build();
        } catch (Exception e) {
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("Error retrieving the applicant pool.")
                    .build();
        }
    }

    @GET
    @Path("/applicants/{applicationId}/full-profile")
    public Response getFullCandidateProfile(@PathParam("applicationId") UUID applicationId) {
        User actor = authContext.getActor();
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }
        // Role-based security check (Staff/Faculty only)
        if (actor.getRole() != UserRole.EMPLOYER) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Access denied: Insufficient privileges for global oversight.")
                    .build();
        }

        UUID employerId = authContext.getActor().getId();

        try {
            // 2. Delegate to the centralized DAO
            EmployerCandidateProfileDTO profile =
                    dashboardDao.getFullCandidateProfile(employerId, applicationId);

            return Response.ok(profile).build();
        } catch (Exception e) {
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("Error retrieving the employeeprofile.")
                    .build();
        }
    }

    @POST
    @Path("/create")
    public Response createJob(JobPosting newJob) {
        User actor = authContext.getActor();
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }
        // Role-based security check (Staff/Faculty only)
        if (actor.getRole() != UserRole.EMPLOYER) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Access denied: Insufficient privileges for global oversight.")
                    .build();
        }

        // 1. Get the authenticated employer's ID
        UUID employerId = authContext.getActor().getId();

        // 2. Set necessary system fields
        newJob.setEmployerId(employerId);
        newJob.setCreatedAt(LocalDateTime.now());
        newJob.setIsActive(true); // Default to active

        // 3. Persist the new job to the database
        jobPostingDao.create(newJob);

        return Response.status(Response.Status.CREATED).entity(newJob).build();
    }

    @GET
    @Path("/{jobId}/details")
    public Response getJobDetails(@PathParam("jobId") UUID jobId) {
        User actor = authContext.getActor();
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }
        // Role-based security check (Staff/Faculty only)
        if (actor.getRole() != UserRole.EMPLOYER) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Access denied: Insufficient privileges for global oversight.")
                    .build();
        }

        return Response.ok(jobPostingDao.getEmployerJobDetailView(jobId, actor.getId())).build();
    }

    @GET
    @Path("/applicants/{applicationId}/resume")
    @Produces(MediaType.APPLICATION_OCTET_STREAM)
    public Response downloadResume(@PathParam("applicationId") UUID applicationId) {
        UUID employerId = authContext.getActor().getId();

        // 1. Get the resume_url and verify ownership in one go
        String resumeUrl = dashboardDao.getResumeUrlIfAuthorized(employerId, applicationId);

        if (resumeUrl == null || resumeUrl.isEmpty()) {
            return Response.status(Response.Status.NOT_FOUND)
                    .entity("Resume not found or access denied.")
                    .build();
        }

        // 2. Fetch the file from your storage (S3, Local Disk, etc.)
        // For this example, we assume a local file path or cloud utility
        File resumeFile = new File("/path/to/uploads/" + resumeUrl);

        if (!resumeFile.exists()) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }

        // 3. Return the file with a 'Content-Disposition' header to trigger download
        return Response.ok(resumeFile)
                .header("Content-Disposition", "attachment; filename=\"" + resumeUrl + "\"")
                .build();
    }

    @PATCH
    @Path("/applicants/{applicationId}/status")
    public Response updateStatus(
            @PathParam("applicationId") UUID applicationId,
            @QueryParam("newStatus") String newStatus) {

        User actor = authContext.getActor();
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }
        // Role-based security check (Staff/Faculty only)
        if (actor.getRole() != UserRole.EMPLOYER) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Access denied: Insufficient privileges for global oversight.")
                    .build();
        }

        UUID employerId = authContext.getActor().getId();

        boolean success =
                dashboardDao.updateApplicationStatus(employerId, applicationId, newStatus);

        if (success) {
            if ("INTERVIEW_SCHEDULED".equals(newStatus)) {
                // Fetch student info & job info from DAO
                var info = dashboardDao.getApplicantNotificationDetails(applicationId);

                emailService.sendInterviewInvitation(
                        info.studentEmail(),
                        info.studentName(),
                        info.jobTitle(),
                        info.companyName());
            }
            return Response.ok().entity("Status updated to " + newStatus).build();
        } else {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Update failed: Unauthorized or application not found.")
                    .build();
        }
    }

    @PUT
    @Path("/jobs/{jobId}/update")
    public Response updateJob(@PathParam("jobId") UUID jobId, JobPosting updatedJob) {
        User actor = authContext.getActor();
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }
        // Role-based security check (Staff/Faculty only)
        if (actor.getRole() != UserRole.EMPLOYER) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Access denied: Insufficient privileges for global oversight.")
                    .build();
        }

        try {
            // 2. Call the DAO to perform the secure update
            updatedJob.setId(jobId);
            updatedJob.setEmployerId(actor.getId());
            JobPosting success = jobPostingService.updateJob(actor, updatedJob);

            if (success != null) {
                return Response.ok("Job posting updated successfully.").build();
            } else {
                // If no rows were affected, either the job doesn't exist
                // or the employer doesn't own it.
                return Response.status(Response.Status.FORBIDDEN)
                        .entity("Access denied: You do not have permission to edit this job.")
                        .build();
            }
        } catch (Exception e) {
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("An error occurred while updating the job.")
                    .build();
        }
    }

    @PUT
    @Path("/jobs/{jobId}/status")
    public Response updateJobStatus(@PathParam("jobId") UUID jobId, boolean isActive) {
        User actor = authContext.getActor();
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }
        // Role-based security check (Staff/Faculty only)
        if (actor.getRole() != UserRole.EMPLOYER) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Access denied: Insufficient privileges for global oversight.")
                    .build();
        }

        try {
            // 2. Call the DAO to perform the secure update
            jobPostingService.setJobStatus(actor, jobId, isActive);
            return Response.ok("Job posting updated successfully.").build();

        } catch (SecurityException e) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Access denied: You do not have permission to edit this job.")
                    .build();
        } catch (Exception e) {
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("An error occurred while updating the job.")
                    .build();
        }
    }
}
