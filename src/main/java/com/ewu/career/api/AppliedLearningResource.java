package com.ewu.career.api;

import com.ewu.career.entity.AppliedLearningExperience;
import com.ewu.career.entity.LearningType;
import com.ewu.career.entity.User;
import com.ewu.career.service.AppliedLearningService;
import com.ewu.career.service.WorkflowService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * REST API for managing Applied Learning Experiences. Handles the 16 types and coordinates workflow
 * initiation.
 */
@Path("/applied-learning")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class AppliedLearningResource {

    @Inject private AppliedLearningService learningService;

    @Inject private WorkflowService workflowService;

    /** Inject the current authenticated user. */
    @Inject User actor;

    /** Retrieves all experiences for a specific student. Used by the Student Portal Dashboard. */
    @GET
    @Path("/student/{studentId}")
    public Response getStudentExperiences(@PathParam("studentId") UUID studentId) {
        List<AppliedLearningExperience> experiences = learningService.findByStudent(studentId);
        return Response.ok(experiences).build();
    }

    /**
     * Submits a new experience and initiates the first approval step. Maps the React form data to
     * the Postgres JSONB structure.
     */
    @POST
    @Path("/create")
    public Response createExperience(Map<String, Object> payload) {
        // In production, 'actor' would be resolved from the Okta JWT context
        // Here we map the payload to the entity
        AppliedLearningExperience experience = new AppliedLearningExperience();
        experience.setStudentId(UUID.fromString((String) payload.get("studentId")));
        experience.setTitle((String) payload.get("title"));
        experience.setType(LearningType.valueOf((String) payload.get("type")));
        experience.setOrganizationName((String) payload.get("organizationName"));

        // Handle dynamic metadata for the 16 types
        if (payload.containsKey("typeSpecificData")) {
            experience.setTypeSpecificData((Map<String, Object>) payload.get("typeSpecificData"));
        }

        // 1. Save the Experience
        AppliedLearningExperience savedExp = learningService.create(null, experience);

        // 2. Initiate the first "No-Login" Workflow step
        String approverEmail = (String) payload.get("approverEmail");
        String approverName = (String) payload.get("approverName");

        if (approverEmail != null) {
            workflowService.initiateApprovalStep(savedExp, approverEmail, approverName, 1);
        }

        return Response.status(Response.Status.CREATED).entity(savedExp).build();
    }

    /** Filters experiences by type for administrative reporting. */
    @GET
    @Path("/filter")
    public Response getByType(@QueryParam("type") LearningType type) {
        return Response.ok(learningService.findByType(type)).build();
    }
}
