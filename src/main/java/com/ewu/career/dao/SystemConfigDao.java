package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.entity.SystemConfig;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.persistence.EntityManager;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class SystemConfigDao {

    @Inject
    @Named("DefaultJpaDao")
    private JpaDao jpa;

    public List<SystemConfig> findAll() {
        return jpa.selectAll("SELECT u FROM SystemConfig u", SystemConfig.class);
    }

    /** Retrieves a configuration value by key. */
    public String getValue(String key, String defaultValue) {
        SystemConfig config = jpa.find(SystemConfig.class, key);
        return (config != null) ? config.getValue() : defaultValue;
    }

    /** Helper for boolean configuration toggles. */
    public boolean getBooleanValue(String key) {
        return Boolean.parseBoolean(getValue(key, "false"));
    }

    /** Updates an existing configuration and logs the staff member responsible. */
    public void updateConfig(String key, String value, UUID staffId) {
        SystemConfig config = jpa.find(SystemConfig.class, key);

        if (config != null) {
            config.setValue(value);
            config.setUpdatedBy(staffId);
            config.setUpdatedAt(LocalDateTime.now());
            // Using jpa.update if the base DAO provides a specialized merge wrapper
            jpa.update(config);
        }
    }

    /** Accessor for the shared EntityManager via the injected JpaDao. */
    private EntityManager getEntityManager() {
        return jpa.getEntityManager();
    }
}
