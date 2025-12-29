package com.ewu.career.api;

import com.ewu.career.api.security.AuthContext;
import com.ewu.career.dao.VolunteerDao;
import com.ewu.career.dto.StudentProjectDTO;
import com.ewu.career.entity.VolunteerLog;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;
import java.util.UUID;

@Path("/student/volunteer")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class VolunteerLogResource {

    @Inject VolunteerDao volunteerDao;

    @Inject AuthContext authContext;

    @GET
    @Path("/my-active-projects")
    public List<StudentProjectDTO> getMyProjects() {
        // Retrieve the logged-in student's ID from the security context
        return volunteerDao.getStudentActiveProjects(authContext.getActor().getId());
    }

    @POST
    @Path("/log")
    public Response submitImpactLog(VolunteerLog log) {
        UUID currentStudentId = authContext.getActor().getId();

        // 1. Force the student ID to be the authenticated user for security
        log.setStudentId(currentStudentId);

        // 2. Set default status
        log.setStatus("PENDING");

        // 3. Persist the record
        volunteerDao.create(log);

        return Response.status(Response.Status.CREATED).build();
    }
}
