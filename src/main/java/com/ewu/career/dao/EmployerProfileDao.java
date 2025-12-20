package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.entity.EmployerProfile;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Stateless
@Named("EmployerProfileDao")
public class EmployerProfileDao {

    @Inject
    @Named("DefaultJpaDao")
    private JpaDao jpa;

    public EmployerProfile find(UUID userId) {
        return jpa.find(EmployerProfile.class, userId);
    }

    /** Retrieves employers that are pending administrative approval. */
    public List<EmployerProfile> findPendingApproval() {
        String query = "SELECT e FROM EmployerProfile e WHERE e.isApproved = false";
        return jpa.selectAll(query, EmployerProfile.class);
    }

    /** Finds employers by industry for targeted career campaigns. */
    public List<EmployerProfile> findByIndustry(String industry) {
        String query = "SELECT e FROM EmployerProfile e WHERE e.industry = :industry";
        Map<String, Object> params = new HashMap<>();
        params.put("industry", industry);
        return jpa.selectAllWithParameters(query, EmployerProfile.class, params);
    }

    public EmployerProfile create(EmployerProfile entity) {
        return jpa.create(entity);
    }

    public EmployerProfile update(EmployerProfile entity) {
        return jpa.update(entity);
    }
}
