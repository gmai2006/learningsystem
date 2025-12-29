package com.ewu.career.api;

import com.ewu.career.api.security.AuthContext;
import com.ewu.career.dao.StudentPrivacyDao;
import com.ewu.career.dto.PagedAccessLogs;
import com.ewu.career.entity.User;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

@Path("/student/privacy")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class StudentPrivacyResource {

    @Inject private StudentPrivacyDao studentPrivacyDao;

    @Inject private AuthContext authContext;

    @GET
    public Response findByUserId(
            @QueryParam("page") @DefaultValue("0") int page,
            @QueryParam("size") @DefaultValue("20") int size) {
        // 1. Identify the current student from the Security Context
        final User student = authContext.getActor();

        if (student == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("User context not found.")
                    .build();
        }

        final PagedAccessLogs privacy =
                studentPrivacyDao.getPagedAccessLogs(student.getId(), page, size);
        return Response.ok(privacy).build();
    }

    @PATCH
    @Path("toggle")
    @Transactional
    public Response updatePrivacy(boolean isRestricted) {
        // 1. Identify the current student from the Security Context
        User student = authContext.getActor();

        if (student == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("User context not found.")
                    .build();
        }

        studentPrivacyDao.updatePrivacyFlag(student.getId(), isRestricted);

        return Response.ok().build();
    }
}
