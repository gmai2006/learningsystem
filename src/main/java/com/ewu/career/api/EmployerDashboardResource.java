package com.ewu.career.api;

import com.ewu.career.api.security.AuthContext;
import com.ewu.career.dao.EmployerDashboardDao;
import com.ewu.career.dao.JobPostingDao;
import com.ewu.career.dto.EmployerDashboardSummary;
import com.ewu.career.entity.JobPosting;
import com.ewu.career.entity.User;
import com.ewu.career.entity.UserRole;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.time.LocalDateTime;
import java.util.UUID;

@Path("/employer/dashboard")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class EmployerDashboardResource {

    @Inject private EmployerDashboardDao dashboardDao;

    @Inject private JobPostingDao jobPostingDao;

    @Inject private AuthContext authContext; // To retrieve the current employer's ID

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
    @Path("/my-postings")
    public Response getMyJobs() {
        UUID employerId = authContext.getActor().getId();
        return Response.ok(dashboardDao.getEmployerJobPostings(employerId)).build();
    }

    @POST
    @Path("/create")
    public Response createJob(JobPosting newJob) {
        // 1. Get the authenticated employer's ID
        UUID employerId = authContext.getActor().getId();

        // 2. Set necessary system fields
        newJob.setId(UUID.randomUUID());
        newJob.setEmployerId(employerId);
        newJob.setCreatedAt(LocalDateTime.now());
        newJob.setActive(true); // Default to active

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
}
