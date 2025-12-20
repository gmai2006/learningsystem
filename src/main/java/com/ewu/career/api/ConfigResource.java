package com.ewu.career.api;

import com.ewu.career.api.security.AuthContext;
import com.ewu.career.dao.SystemConfigDao;
import com.ewu.career.dto.ConfigUpdateRequest;
import com.ewu.career.entity.SystemConfig;
import com.ewu.career.entity.User;
import com.ewu.career.interceptor.AuditAction;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;

@Path("/admin/config")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class ConfigResource {

    @Inject private SystemConfigDao configDao;

    @Inject private AuthContext authContext; // Injected to access the authenticated User entity

    /** Retrieves all system configurations. */
    @GET
    public Response getAllConfigs() {
        List<SystemConfig> configs = configDao.findAll();
        return Response.ok(configs).build();
    }

    /** Batch updates system settings using the AuthContext actor. */
    @PUT
    @AuditAction("Updated Global System Settings")
    public Response updateConfigs(ConfigUpdateRequest request) {
        // Retrieve the authenticated User entity from AuthContext
        User staffMember = authContext.getActor();

        // Use the staff member's real ID for the update audit trail
        request.getSettings()
                .forEach(
                        (key, value) -> {
                            configDao.updateConfig(key, value, staffMember.getId());
                        });

        return Response.ok()
                .entity("Configuration updated successfully by " + staffMember.getEmail())
                .build();
    }
}
