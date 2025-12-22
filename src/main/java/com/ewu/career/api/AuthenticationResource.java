package com.ewu.career.api;

import com.ewu.career.api.security.AuthContext;
import com.ewu.career.entity.User;
import com.ewu.career.service.UserService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;

@Path("/users")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class AuthenticationResource {

    @Inject private UserService userService;

    /** Inject the current authenticated user. */
    @Inject User actor;

    @Inject private AuthContext authContext;

    @GET
    public User getActive() {
        return authContext.getActor();
    }
}
