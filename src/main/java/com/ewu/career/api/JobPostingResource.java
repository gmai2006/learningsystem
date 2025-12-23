package com.ewu.career.api;

import com.ewu.career.api.security.AuthContext;
import com.ewu.career.dao.JobApplicationDao;
import com.ewu.career.dto.EmployerJobViewDTO;
import com.ewu.career.dto.JobFilters;
import com.ewu.career.dto.JobPostingDTO;
import com.ewu.career.entity.JobPosting;
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

    @Inject private JobApplicationDao jobApplicationDao;

    /** Inject the current authenticated user. */
    @Inject AuthContext authContext;

    @GET
    @Path("/employer-view")
    public Response getJobsForEmployer() {
        if (authContext.getActor() == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }

        if (authContext.getActor().getRole() != UserRole.EMPLOYER) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Access denied: Insufficient privileges for global oversight.")
                    .build();
        }

        // Security: Only fetch jobs belonging to the logged-in employer
        UUID employerId = authContext.getActor().getId();
        List<EmployerJobViewDTO> jobs =
                jobPostingService.getEmployerView(employerId, authContext.getActor());
        return Response.ok(jobs).build();
    }

    /**
     * Retrieves a specialized view of job postings for students. Includes the 'isApplied' status
     * for the logged-in user and supports dynamic filtering. * Accessible via: GET
     * /api/jobs/student-view?search=...&onCampus=...
     */
    @GET
    @Path("/student-view")
    public Response getJobsForStudent(@BeanParam JobFilters filters) {
        if (authContext.getActor() == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }

        // 1. Extract the current student ID from the security context
        UUID studentId = authContext.getActor().getId();

        // 2. Delegate to the DAO to perform the filtered query with subquery-based DTO mapping
        List<JobPostingDTO> jobs = jobApplicationDao.getStudentJobView(studentId, filters);
        return Response.ok(jobs).build();
    }

    /**
     * Administrative endpoint for Staff to view every job posting in the system. Supports the
     * "Real-time visualization" requirement for oversight.
     */
    @GET
    @Path("/admin/all")
    public Response getAllJobsForStaff() {
        if (authContext.getActor() == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }
        // Role-based security check (Staff/Faculty only)
        if (authContext.getActor().getRole() != UserRole.STAFF
                && authContext.getActor().getRole() != UserRole.FACULTY) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Access denied: Insufficient privileges for global oversight.")
                    .build();
        }

        // Calls a DAO method that ignores fundingSource and isActive flags
        List<JobPosting> allJobs = jobPostingService.findAllPostings(authContext.getActor());
        return Response.ok(allJobs).build();
    }

    /** Creates a new job posting. Restricted to Employers and Staff. */
    @POST
    public Response createJob(JobPosting job) {
        if (authContext.getActor() == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }
        // Role-based security check (Staff/Faculty only)
        if (authContext.getActor().getRole() != UserRole.STAFF
                && authContext.getActor().getRole() != UserRole.FACULTY) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Access denied: Insufficient privileges for global oversight.")
                    .build();
        }
        try {
            JobPosting created = jobPostingService.createJob(authContext.getActor(), job);
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
        if (authContext.getActor() == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }
        // Role-based security check (Staff/Faculty only)
        if (authContext.getActor().getRole() != UserRole.STAFF
                && authContext.getActor().getRole() != UserRole.FACULTY) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Access denied: Insufficient privileges for global oversight.")
                    .build();
        }
        job.setId(id);
        try {
            JobPosting updated = jobPostingService.updateJob(authContext.getActor(), job);
            return Response.ok(updated).build();
        } catch (SecurityException e) {
            return Response.status(Response.Status.FORBIDDEN).entity(e.getMessage()).build();
        }
    }

    /** Toggles a job's active status (e.g., closing a position). */
    @PATCH
    @Path("/{id}/status")
    public Response toggleStatus(@PathParam("id") UUID id, @QueryParam("active") boolean active) {
        if (authContext.getActor() == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }
        // Role-based security check (Staff/Faculty only)
        if (authContext.getActor().getRole() != UserRole.STAFF
                && authContext.getActor().getRole() != UserRole.FACULTY) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Access denied: Insufficient privileges for global oversight.")
                    .build();
        }
        try {
            jobPostingService.setJobStatus(authContext.getActor(), id, active);
            return Response.noContent().build();
        } catch (SecurityException e) {
            return Response.status(Response.Status.FORBIDDEN).entity(e.getMessage()).build();
        }
    }
}
