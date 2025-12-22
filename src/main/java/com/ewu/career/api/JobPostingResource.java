package com.ewu.career.api;

import com.ewu.career.entity.JobPosting;
import com.ewu.career.entity.User;
import com.ewu.career.entity.UserRole;
import com.ewu.career.service.JobPostingService;
import com.ewu.career.service.UserService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;
import java.util.UUID;

@Path("/jobs")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class JobPostingResource {

    @Inject private JobPostingService jobPostingService;

    @Inject private UserService userService;

    /** Inject the current authenticated user. */
    @Inject User actor;

    /**
     * Retrieves the job list tailored for the logged-in student. Enforces funding visibility logic
     * (Work Study vs. Non-Work Study).
     */
    @GET
    @Path("/student-view")
    public Response getJobsForStudent() {
        if (actor == null) {
            return Response.status(401).entity("Not authenticated").build();
        }

        List<JobPosting> jobs = jobPostingService.getJobsForStudent(actor);
        return Response.ok(jobs).build();
    }

    /**
     * Administrative endpoint for Staff to view every job posting in the system. Supports the
     * "Real-time visualization" requirement for oversight.
     */
    @GET
    @Path("/admin/all")
    public Response getAllJobsForStaff() {
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }
        // Role-based security check (Staff/Faculty only)
        if (actor.getRole() != UserRole.STAFF && actor.getRole() != UserRole.FACULTY) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Access denied: Insufficient privileges for global oversight.")
                    .build();
        }

        // Calls a DAO method that ignores fundingSource and isActive flags
        List<JobPosting> allJobs = jobPostingService.findAllPostings(actor);
        return Response.ok(allJobs).build();
    }

    /** Creates a new job posting. Restricted to Employers and Staff. */
    @POST
    public Response createJob(JobPosting job) {
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }
        // Role-based security check (Staff/Faculty only)
        if (actor.getRole() != UserRole.STAFF && actor.getRole() != UserRole.FACULTY) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Access denied: Insufficient privileges for global oversight.")
                    .build();
        }
        try {
            JobPosting created = jobPostingService.createJob(actor, job);
            return Response.status(Response.Status.CREATED).entity(created).build();
        } catch (SecurityException e) {
            return Response.status(Response.Status.FORBIDDEN).entity(e.getMessage()).build();
        }
    }

    /**
     * Updates an existing job posting. Verified against the original employer or administrative
     * oversight.
     */
    @PUT
    @Path("/{id}")
    public Response updateJob(@PathParam("id") UUID id, JobPosting job) {
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }
        // Role-based security check (Staff/Faculty only)
        if (actor.getRole() != UserRole.STAFF && actor.getRole() != UserRole.FACULTY) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Access denied: Insufficient privileges for global oversight.")
                    .build();
        }
        job.setId(id);
        try {
            JobPosting updated = jobPostingService.updateJob(actor, job);
            return Response.ok(updated).build();
        } catch (SecurityException e) {
            return Response.status(Response.Status.FORBIDDEN).entity(e.getMessage()).build();
        }
    }

    /** Toggles a job's active status (e.g., closing a position). */
    @PATCH
    @Path("/{id}/status")
    public Response toggleStatus(@PathParam("id") UUID id, @QueryParam("active") boolean active) {
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }
        // Role-based security check (Staff/Faculty only)
        if (actor.getRole() != UserRole.STAFF && actor.getRole() != UserRole.FACULTY) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Access denied: Insufficient privileges for global oversight.")
                    .build();
        }
        try {
            jobPostingService.setJobStatus(actor, id, active);
            return Response.noContent().build();
        } catch (SecurityException e) {
            return Response.status(Response.Status.FORBIDDEN).entity(e.getMessage()).build();
        }
    }
}
