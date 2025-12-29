package com.ewu.career.api;

import com.ewu.career.api.security.AuthContext;
import com.ewu.career.dao.EventDao;
import com.ewu.career.dto.ErrorDTO;
import com.ewu.career.dto.MessageDTO;
import jakarta.inject.Inject;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.Response;
import java.util.UUID;

@Path("/employer/events")
public class EmployerCheckInResource {

    @Inject EventDao eventDao;

    @Inject private AuthContext authContext;

    @POST
    @Path("/{eventId}/check-in/{studentId}")
    public Response checkInStudent(
            @Context HttpServletRequest request,
            @PathParam("eventId") UUID eventId,
            @PathParam("studentId") UUID studentId) {

        UUID employerId = authContext.getActor().getId();

        try {
            eventDao.processCheckIn(eventId, studentId, employerId, request);
            return Response.ok(new MessageDTO("Check-in successful!")).build();
        } catch (Exception e) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity(new ErrorDTO(e.getMessage()))
                    .build();
        }
    }
}
