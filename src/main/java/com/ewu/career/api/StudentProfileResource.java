package com.ewu.career.api;

import com.ewu.career.api.security.AuthContext;
import com.ewu.career.dao.StudentProfileDao;
import com.ewu.career.dto.StudentProfileDTO;
import com.ewu.career.entity.User;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;
import java.util.UUID;

@Path("/student/profile")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class StudentProfileResource {

    @Inject private StudentProfileDao studentProfileDao;

    @Inject private AuthContext authContext;

    @GET
    public Response findByUserId() {
        // 1. Identify the current student from the Security Context
        final User student = authContext.getActor();

        if (student == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("User context not found.")
                    .build();
        }

        final StudentProfileDTO profile = studentProfileDao.findByUserId(student.getId());
        return Response.ok(profile).build();
    }

    @PATCH
    public Response updateProfile(StudentProfileDTO updatedProfile) {
        // 1. Identify the current student from the Security Context
        User student = authContext.getActor();

        if (student == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("User context not found.")
                    .build();
        }
        UUID currentUserId = authContext.getActor().getId();

        // Save profile fields (GPA, Bio, etc.)
        studentProfileDao.updateStudentProfile(updatedProfile, student);

        // Save skills separately using our manual logic
        if (updatedProfile.skills() != null) {
            studentProfileDao.updateSkills(currentUserId, List.copyOf(updatedProfile.skills()));
        }

        return Response.ok(updatedProfile).build();
    }
}
