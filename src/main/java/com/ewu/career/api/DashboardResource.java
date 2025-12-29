package com.ewu.career.api;

import com.ewu.career.api.security.AuthContext;
import com.ewu.career.dao.EventDao;
import com.ewu.career.dto.CommandCenterStats;
import com.ewu.career.entity.Event;
import com.ewu.career.entity.User;
import com.ewu.career.entity.UserRole;
import com.ewu.career.service.AppliedLearningService;
import com.ewu.career.service.DashboardService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Path("/admin/dashboard")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class DashboardResource {

    @Inject private DashboardService dashboardService;
    @Inject private AppliedLearningService learningService;

    @Inject private AuthContext authContext; // Injected to verify the identity of the staff member

    @Inject EventDao eventDao;

    /**
     * Aggregates data from all silos for the Command Center. Uses AuthContext to ensure the actor
     * has administrative privileges.
     */
    @GET
    @Path("/stats")
    public Response getCommandCenterStats() {
        try {
            // Retrieve the authenticated User entity
            User actor = authContext.getActor();
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

            Map<String, Object> extended = learningService.getExtendedStats();
            // Fetch the aggregated statistics for the UI
            CommandCenterStats stats = dashboardService.getAggregatedStats();
            stats.activePlacements = (Long) extended.get("activePlacements");
            stats.completionRate = (String) extended.get("completionRate");

            return Response.ok(stats).build();

        } catch (IllegalStateException e) {
            // Thrown by AuthContext if no user is found
            return Response.status(Response.Status.UNAUTHORIZED).build();
        } catch (Exception e) {
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("Error retrieving Command Center metrics.")
                    .build();
        }
    }

    @GET
    @Path("events")
    public Response getEvents(@QueryParam("status") String status) {
        User actor = authContext.getActor();
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

        UUID userId = authContext.getActor().getId();
        boolean isStaff =
                authContext.getActor().getRole().equals("STAFF")
                        || authContext.getActor().getRole().equals("FACULTY");

        List<Event> events = eventDao.getEventsByStatus(userId, status, isStaff);

        return Response.ok(events).build();
    }
}
