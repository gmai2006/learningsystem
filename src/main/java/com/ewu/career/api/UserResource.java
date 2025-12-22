package com.ewu.career.api;

import com.ewu.career.api.security.AuthContext;
import com.ewu.career.dao.AuditLogDao;
import com.ewu.career.entity.AuditLog;
import com.ewu.career.entity.User;
import com.ewu.career.entity.UserRole;
import com.ewu.career.service.UserService;
import com.ewu.career.util.HttpUtils;
import jakarta.inject.Inject;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Path("/admin/users")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class UserResource {

    @Inject private UserService userService;

    @Inject private AuditLogDao auditLogDao;

    /** Inject the current authenticated user. */
    @Inject User actor;

    @Inject private AuthContext authContext;

    @GET
    @Path("/validate-banner/{bannerId}")
    public Response validateBannerId(@PathParam("bannerId") String bannerId) {
        // In a real scenario, this calls the Banner API/Database
        // For now, we simulate a lookup
        if (bannerId.startsWith("9")) { // Mocking a "not found" scenario
            return Response.status(Response.Status.NOT_FOUND)
                    .entity("No student found with this ID.")
                    .build();
        }

        // Simulate finding a student
        Map<String, String> student =
                Map.of(
                        "firstName", "Example",
                        "lastName", "Student",
                        "email", "estudent@ewu.edu");
        return Response.ok(student).build();
    }

    /** Endpoint for the User Directory. Supports search, role filtering, and pagination. */
    @GET
    public Response getUsers(
            @QueryParam("limit") @DefaultValue("15") int limit,
            @QueryParam("offset") @DefaultValue("0") int offset,
            @QueryParam("search") String search,
            @QueryParam("role") String role) {

        // 1. Security check via AuthContext
        User actor = authContext.getActor();
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }

        if (actor.getRole() != UserRole.STAFF) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Only Staff can access the Recruitment Silo.")
                    .build();
        }

        // 2. Fetch data and count
        List<User> users = userService.findUsers(limit, offset, search, role);
        long totalCount = userService.getTotalUserCount(search, role);

        // 3. Return response with total count header for the frontend
        return Response.ok(users)
                .header("X-Total-Count", totalCount)
                .header(
                        "Access-Control-Expose-Headers",
                        "X-Total-Count") // Ensure JS can read the header
                .build();
    }

    /** Retrieve a specific user by ID. */
    @GET
    @Path("/{id}")
    public Response getUser(@PathParam("id") UUID id) {
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }

        if (actor.getRole() != UserRole.STAFF) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Only Staff can access the Recruitment Silo.")
                    .build();
        }
        User user = userService.find(id);
        if (user == null) {
            return Response.status(Response.Status.NOT_FOUND).build();
        }
        return Response.ok(user).build();
    }

    /** Update an existing user's details. */
    @PUT
    @Path("/{id}")
    public Response updateUser(
            @Context HttpServletRequest request, @PathParam("id") UUID id, User updatedUser) {
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }

        if (actor.getRole() != UserRole.STAFF) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Only Staff can access the Recruitment Silo.")
                    .build();
        }
        updatedUser.setId(id);
        User result = userService.update(updatedUser, actor);

        // Audit Log Entry
        createAuditLog(actor, request, "USER_UPDATED", "Updated user ID: " + id);
        return Response.ok(result).build();
    }

    /** Delete a user by ID. */
    @DELETE
    @Path("/{id}")
    public Response deleteUser(@Context HttpServletRequest request, @PathParam("id") UUID id) {
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }

        if (actor.getRole() != UserRole.STAFF) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Only Staff can access the Recruitment Silo.")
                    .build();
        }
        userService.delete(id, actor, request);
        // Audit Log Entry
        createAuditLog(actor, request, "USER_DELETED", "Deleted user ID: " + id);
        return Response.noContent().build();
    }

    /** Exports the user directory to a CSV file. Protected: Staff/Faculty only. */
    @GET
    @Path("/export")
    @Produces("text/csv")
    public Response exportUserDirectory() {
        // 1. Security check
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }

        if (actor.getRole() != UserRole.STAFF) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Only Staff can access the Recruitment Silo.")
                    .build();
        }

        // 2. Fetch all users (limit to 2000 for performance)
        List<User> users = userService.findUsers(2000, 0, null, null);

        // 3. Generate CSV Content
        StringBuilder csv = getStringBuilder(users);

        // 4. Return as a downloadable file
        return Response.ok(csv.toString())
                .header("Content-Disposition", "attachment; filename=ewu_user_directory.csv")
                .header("Access-Control-Expose-Headers", "Content-Disposition")
                .build();
    }

    @POST
    @Consumes(MediaType.APPLICATION_JSON)
    public Response createUser(User newUser) {
        // 1. Security Check
        User actor = authContext.getActor();
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }

        if (actor.getRole() != UserRole.STAFF) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Only Staff can access the Recruitment Silo.")
                    .build();
        }

        // 2. Simple Validation
        if (newUser.getEmail() == null || newUser.getRole() == null) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("Email and Role are required.")
                    .build();
        }

        if (UserRole.STUDENT.equals(newUser.getRole())
                && (newUser.getBannerId() == null || newUser.getBannerId().isEmpty())) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("Banner ID is mandatory for Student accounts.")
                    .build();
        }

        try {
            // 3. Save via Service/DAO
            userService.create(newUser, actor);
            return Response.status(Response.Status.CREATED).entity(newUser).build();
        } catch (Exception e) {
            return Response.status(Response.Status.INTERNAL_SERVER_ERROR)
                    .entity("Error creating user: " + e.getMessage())
                    .build();
        }
    }

    private static StringBuilder getStringBuilder(List<User> users) {
        StringBuilder csv = new StringBuilder();
        csv.append("First Name,Last Name, Email,Role,Registration Date\n");

        for (User u : users) {
            csv.append(
                    String.format(
                            "\"%s\",\"\"%s\",%s,%s,%s\n",
                            u.getFirstName().replace("\"", "'"), // Escape quotes in names
                            u.getLastName().replace("\"", "'"),
                            u.getEmail(),
                            u.getRole(),
                            u.getCreatedAt() != null ? u.getCreatedAt() : "N/A"));
        }
        return csv;
    }

    private void createAuditLog(
            User actor, HttpServletRequest request, String action, String description) {
        final String ipAddress = HttpUtils.getClientIP(request);
        AuditLog log =
                new AuditLog(
                        actor.getId(),
                        actor.getFirstName() + " " + actor.getLastName(),
                        action,
                        "USER",
                        null,
                        description,
                        ipAddress);

        auditLogDao.create(log);
    }
}
