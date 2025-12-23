package com.ewu.career.api;

import com.ewu.career.api.security.AuthContext;
import com.ewu.career.dao.JobApplicationDao;
import com.ewu.career.dto.JobApplicationDTO;
import com.ewu.career.entity.JobApplication;
import com.ewu.career.entity.User;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;
import java.util.UUID;

@Path("/applications")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class JobApplicationResource {

    @Inject private JobApplicationDao applicationDao;

    @Inject private AuthContext authContext;

    /** Submit a new job application. Accessible by: STUDENTS */
    @POST
    public Response applyForJob(JobApplication application) {
        User currentUser = authContext.getActor();

        // Security: Ensure student_id matches the logged-in user
        application.setStudentId(currentUser.getId());

        // Business Logic: Prevent duplicate applications
        if (applicationDao.exists(application.getStudentId(), application.getJobId())) {
            return Response.status(Response.Status.CONFLICT)
                    .entity("You have already applied for this position.")
                    .build();
        }

        JobApplication saved =
                applicationDao.submitApplication(
                        currentUser.getId(), application.getJobId(), application.getNotes());
        return Response.status(Response.Status.CREATED).entity(saved).build();
    }

    /** Get all applications for the current logged-in student. */
    @GET
    @Path("/my-applications")
    public List<JobApplicationDTO> getMyApplications() {
        UUID studentId = authContext.getActor().getId();
        return applicationDao.findByStudentId(studentId);
    }

    @DELETE
    @Path("/{id}/withdraw")
    public Response withdraw(@PathParam("id") UUID applicationId) {
        UUID studentId = authContext.getActor().getId();

        try {
            applicationDao.withdrawApplication(applicationId, studentId);
            return Response.ok().entity("Application withdrawn successfully").build();
        } catch (IllegalStateException e) {
            return Response.status(Response.Status.BAD_REQUEST).entity(e.getMessage()).build();
        }
    }

    /** Get all applications for a specific job (for Employers/Staff). */
    @GET
    @Path("/job/{jobId}")
    public List<JobApplication> getApplicationsByJob(@PathParam("jobId") UUID jobId) {
        // In production, add a check here to ensure the requester owns the job posting
        return applicationDao.findByJobId(jobId);
    }

    /** Update application status (e.g., REVIEWING, ACCEPTED, REJECTED). */
    @PATCH
    @Path("/{id}/status")
    public Response updateStatus(@PathParam("id") UUID id, @QueryParam("status") String status) {
        if (status == null || status.isEmpty()) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("Status is required")
                    .build();
        }

        applicationDao.updateStatus(id, status);
        return Response.ok().entity("Status updated successfully").build();
    }
}
