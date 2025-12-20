package com.ewu.career.dao;

import com.ewu.career.entity.Workflow;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Stateless
@Named("WorkflowDao")
public class WorkflowDao {

    @Inject
    @Named("DefaultJpaDao")
    private com.ewu.career.dao.core.JpaDao jpa;

    /** Securely retrieves a workflow using the email token for "no-login" approvals. */
    public Workflow findByToken(String authToken) {
        String query =
                "SELECT w FROM Workflow w WHERE w.authToken = :token AND w.tokenExpiry >"
                        + " CURRENT_TIMESTAMP";
        Map<String, Object> params = new HashMap<>();
        params.put("token", authToken);
        List<Workflow> list = jpa.selectAllWithParameters(query, Workflow.class, params);
        return list.isEmpty() ? null : list.get(0);
    }

    public List<Workflow> findByExperience(UUID experienceId) {
        String query =
                "SELECT w FROM Workflow w WHERE w.experienceId = :experienceId ORDER BY w.stepOrder"
                        + " ASC";
        Map<String, Object> params = new HashMap<>();
        params.put("experienceId", experienceId);
        return jpa.selectAllWithParameters(query, Workflow.class, params);
    }

    public Workflow create(Workflow entity) {
        return jpa.create(entity);
    }

    public Workflow update(Workflow entity) {
        return jpa.update(entity);
    }
}
