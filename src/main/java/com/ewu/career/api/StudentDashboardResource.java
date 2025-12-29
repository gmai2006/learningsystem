package com.ewu.career.api;

import com.ewu.career.api.security.AuthContext;
import com.ewu.career.dao.EventDao;
import com.ewu.career.dao.StudentDashboardDao;
import com.ewu.career.dto.StudentDashboardSummary;
import com.ewu.career.entity.User;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.Map;
import java.util.UUID;

@Path("/student/dashboard")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class StudentDashboardResource {

    @Inject private StudentDashboardDao dashboardDao;

    @Inject private AuthContext authContext;

    @Inject private EventDao eventDao;

    /**
     * Retrieves the high-level career progress summary for the logged-in student. Calculated from
     * Job Applications and Applied Learning JSONB metadata.
     */
    @GET
    @Path("/summary")
    public Response getDashboardSummary() {
        // 1. Identify the current student from the Security Context
        User student = authContext.getActor();

        if (student == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("User context not found.")
                    .build();
        }

        // 2. Fetch aggregated summary directly from the DAO
        UUID studentId = student.getId();
        StudentDashboardSummary summary = dashboardDao.getSummary(studentId);

        return Response.ok(summary).build();
    }

    @GET
    @Path("/volunteersummary")
    public Response getStudentVolunteerImpact() {
        // 1. Identify the current student from the Security Context
        User student = authContext.getActor();

        if (student == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("User context not found.")
                    .build();
        }

        // 2. Fetch aggregated summary directly from the DAO
        UUID studentId = student.getId();
        Map<String, Object> summary = dashboardDao.getStudentVolunteerImpact(studentId);

        return Response.ok(summary).build();
    }

    @POST
    @Path("/events/{eventId}/rsvp")
    public Response joinEvent(@PathParam("eventId") UUID eventId) {
        User student = authContext.getActor();

        if (student == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("User context not found.")
                    .build();
        }

        UUID studentId = authContext.getActor().getId();
        try {
            eventDao.rsvpToEvent(eventId, studentId);
            return Response.ok().build();
        } catch (Exception e) {
            return Response.status(Response.Status.BAD_REQUEST).entity(e.getMessage()).build();
        }
    }
}
