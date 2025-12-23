package com.ewu.career.api;

import com.ewu.career.api.security.AuthContext;
import com.ewu.career.dao.LearningDao;
import com.ewu.career.entity.LearningModule;
import jakarta.inject.Inject;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Path("/learning")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class LearningResource {

    @Inject private LearningDao learningDao;

    @Inject private AuthContext authContext;

    /** Retrieves the learning catalog with completion status for the current student. */
    @GET
    @Path("/modules")
    public Response getModules() {
        UUID studentId = authContext.getActor().getId();

        List<LearningModule> allModules = learningDao.findAllActive();
        List<UUID> completedIds = learningDao.getCompletedModuleIds(studentId);

        // Map data to include the weight and completion flag for the UI
        List<Map<String, Object>> response =
                allModules.stream()
                        .map(
                                m -> {
                                    Map<String, Object> map = new HashMap<>();
                                    map.put("id", m.getId());
                                    map.put("title", m.getTitle());
                                    map.put("description", m.getDescription());
                                    map.put("category", m.getCategory());
                                    map.put("moduleType", m.getModuleType());
                                    map.put("durationMinutes", m.getDurationMinutes());
                                    map.put("contentUrl", m.getContentUrl());
                                    map.put(
                                            "weight",
                                            m.getWeight()); // <--- NEW: Points/Weight added to JSON
                                    map.put("isCompleted", completedIds.contains(m.getId()));
                                    return map;
                                })
                        .toList();

        return Response.ok(response).build();
    }

    /**
     * Marks a specific module as completed by the student. POST /api/learning/modules/{id}/complete
     */
    @POST
    @Path("/modules/{id}/complete")
    public Response completeModule(@PathParam("id") UUID moduleId) {
        UUID studentId = authContext.getActor().getId();

        learningDao.markAsComplete(studentId, moduleId);

        // Return updated readiness score
        int newScore = learningDao.getReadinessScore(studentId);

        Map<String, Object> result = new HashMap<>();
        result.put("message", "Module completed successfully");
        result.put("readinessScore", newScore);

        return Response.ok(result).build();
    }
}
