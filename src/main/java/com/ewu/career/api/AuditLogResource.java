package com.ewu.career.api;

import com.ewu.career.api.security.AuthContext;
import com.ewu.career.dao.AuditLogDao;
import com.ewu.career.entity.AuditLog;
import com.ewu.career.entity.User;
import com.ewu.career.entity.UserRole;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;

@Path("/admin/audit-logs")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class AuditLogResource {

    @Inject private AuditLogDao auditDao;

    @Inject private AuthContext authContext;

    /** Retrieves a full list of system logs. Accessible only by STAFF and FACULTY. */
    @GET
    public Response getFullLogs(
            @QueryParam("limit") @DefaultValue("50") int limit,
            @QueryParam("offset") @DefaultValue("0") int offset) {

        try {
            User actor = authContext.getActor();

            // Security Check
            if (actor.getRole() != UserRole.STAFF && actor.getRole() != UserRole.FACULTY) {
                return Response.status(Response.Status.FORBIDDEN).build();
            }

            List<AuditLog> logs = auditDao.findAll(limit, offset);
            return Response.ok(logs).build();

        } catch (Exception e) {
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("Unable to retrieve system logs.")
                    .build();
        }
    }

    @GET
    @Path("/export")
    @Produces("text/csv")
    public Response exportLogs() {
        User actor = authContext.getActor();
        // Security check: STAFF/FACULTY only
        if (actor.getRole() != UserRole.STAFF && actor.getRole() != UserRole.FACULTY) {
            return Response.status(Response.Status.FORBIDDEN).build();
        }

        List<AuditLog> allLogs = auditDao.findAll(1000, 0); // Export recent 1000

        StringBuilder csv = getStringBuilder(allLogs);

        return Response.ok(csv.toString())
                .header("Content-Disposition", "attachment; filename=ewu_audit_logs.csv")
                .build();
    }

    private static StringBuilder getStringBuilder(List<AuditLog> allLogs) {
        StringBuilder csv = new StringBuilder();
        csv.append("Timestamp,Actor,Action,Target,Details,IP Address\n");

        for (AuditLog log : allLogs) {
            csv.append(
                    String.format(
                            "%s,%s,%s,%s,\"%s\",%s\n",
                            log.getCreatedAt(),
                            log.getActorName(),
                            log.getAction(),
                            log.getTargetType(),
                            log.getDetails().replace("\"", "'"), // Escape quotes
                            log.getIpAddress()));
        }
        return csv;
    }
}
