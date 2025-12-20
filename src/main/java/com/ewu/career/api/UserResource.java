package com.ewu.career.api;

import com.ewu.career.api.security.AuthContext;
import com.ewu.career.entity.User;
import com.ewu.career.service.UserService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;
import java.util.UUID;

@Path("/users")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class UserResource {

    @Inject private UserService userService;

    /** Inject the current authenticated user. */
    @Inject User actor;

    @Inject private AuthContext authContext;

    @GET
    //    @Named("currentUser")
    public User getActive() {
        return authContext.getActor();
    }

    /** List all users for administrative oversight. */
    @GET
    @Path("/all")
    public Response getAllUsers() {
        if (actor == null) {
            return Response.status(401).entity("Not authenticated").build();
        }
        List<User> users = userService.findAll();
        return Response.ok(users).build();
    }

    /** Retrieve a specific user by ID. */
    @GET
    @Path("/{id}")
    public Response getUser(@PathParam("id") UUID id) {
        if (actor == null) {
            return Response.status(401).entity("Not authenticated").build();
        }
        User user = userService.find(id);
        if (user == null) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        return Response.ok(user).build();
    }

    /** Add a new user (Staff/Faculty only). */
    @POST
    public Response createUser(User newUser) {
        if (actor == null) {
            return Response.status(401).entity("Not authenticated").build();
        }
        // actor (Staff/Faculty) is resolved via Interceptor in production
        User created = userService.create(null, newUser);
        return Response.status(Response.Status.CREATED).entity(created).build();
    }

    /** Update an existing user's details. */
    @PUT
    @Path("/{id}")
    public Response updateUser(@PathParam("id") UUID id, User updatedUser) {
        if (actor == null) {
            return Response.status(401).entity("Not authenticated").build();
        }
        updatedUser.setId(id);
        User result = userService.update(null, updatedUser);
        return Response.ok(result).build();
    }

    /** Delete a user by ID. */
    @DELETE
    @Path("/{id}")
    public Response deleteUser(@PathParam("id") UUID id) {
        if (actor == null) {
            return Response.status(401).entity("Not authenticated").build();
        }
        userService.delete(null, id);
        return Response.noContent().build();
    }
}
