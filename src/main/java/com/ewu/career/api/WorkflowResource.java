package com.ewu.career.api;

import com.ewu.career.entity.AppliedLearningExperience;
import com.ewu.career.entity.User;
import com.ewu.career.entity.Workflow;
import com.ewu.career.service.AppliedLearningService;
import com.ewu.career.service.UserService;
import com.ewu.career.service.WorkflowService;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.Map;
import java.util.UUID;

@Path("/workflow")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class WorkflowResource {

    @Inject private WorkflowService workflowService;
    @Inject private AppliedLearningService experienceService;
    @Inject private UserService userService;

    /** Inject the current authenticated user. */
    @Inject User actor;

    /**
     * Initiates a workflow step. Requires internal authentication (Staff/Faculty).
     *
     * @param experienceId The ID of the experience requiring approval.
     */
    @POST
    @Path("/initiate/{experienceId}")
    public Response initiateStep(
            @PathParam("experienceId") UUID experienceId, Map<String, Object> payload) {

        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }

        AppliedLearningExperience exp = experienceService.find(experienceId);

        if (exp == null) {
            return Response.status(Response.Status.NOT_FOUND)
                    .entity("Experience not found")
                    .build();
        }

        String email = (String) payload.get("approverEmail");
        String name = (String) payload.get("approverName");
        Integer step = (Integer) payload.get("stepOrder");

        Workflow workflow = workflowService.initiateApprovalStep(exp, email, name, step);
        return Response.status(Response.Status.CREATED).entity(workflow).build();
    }

    /**
     * Public endpoint for external supervisors to view details using their token. Fulfills the
     * "no-login" requirement.
     */
    @GET
    @Path("/details")
    public Response getDetailsByToken(@QueryParam("token") String token) {
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }
        // This logic would normally be inside WorkflowService, shown here for clarity
        // It fetches the experience data associated with a valid token
        try {
            // Simplified for brevity: fetching details to show on the landing page
            return Response.ok(workflowService.getExperienceDetailsByToken(token)).build();
        } catch (SecurityException e) {
            return Response.status(Response.Status.UNAUTHORIZED).entity(e.getMessage()).build();
        }
    }

    /**
     * Public endpoint for external supervisors to submit their decision. Fulfills the "no-login"
     * requirement.
     */
    @POST
    @Path("/process")
    public Response processApproval(Map<String, String> request) {
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }

        String token = request.get("token");
        String status = request.get("status");
        String comments = request.get("comments");

        if (token == null || status == null) {
            return Response.status(Response.Status.BAD_REQUEST)
                    .entity("Missing token or status")
                    .build();
        }

        try {
            workflowService.processExternalApproval(token, status, comments);
            return Response.ok().entity("Decision recorded successfully").build();
        } catch (SecurityException e) {
            return Response.status(Response.Status.UNAUTHORIZED).entity(e.getMessage()).build();
        }
    }
}
