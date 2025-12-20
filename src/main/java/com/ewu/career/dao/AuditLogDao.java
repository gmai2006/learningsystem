package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.entity.AuditLog;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import java.util.List;

@ApplicationScoped
public class AuditLogDao {

    @Inject
    @Named("DefaultJpaDao")
    private JpaDao jpa;

    /** Fetches the last N activities for the Command Center pulse. */
    public List<AuditLog> findRecent(int limit) {
        return jpa.getEntityManager()
                .createQuery("SELECT a FROM AuditLog a ORDER BY a.createdAt DESC", AuditLog.class)
                .setMaxResults(limit)
                .getResultList();
    }

    /** Paginated retrieval of audit logs, ordered by most recent first. */
    public List<AuditLog> findAll(int limit, int offset) {
        return jpa.getEntityManager()
                .createQuery("SELECT a FROM AuditLog a ORDER BY a.createdAt DESC", AuditLog.class)
                .setFirstResult(offset)
                .setMaxResults(limit)
                .getResultList();
    }

    public List<AuditLog> findByFilters(int limit, int offset, String action) {
        String jpql = "SELECT a FROM AuditLog a ";
        if (action != null && !action.isEmpty()) {
            jpql += "WHERE a.action = :action ";
        }
        jpql += "ORDER BY a.createdAt DESC";

        var query =
                jpa.getEntityManager()
                        .createQuery(jpql, AuditLog.class)
                        .setFirstResult(offset)
                        .setMaxResults(limit);

        if (action != null && !action.isEmpty()) {
            query.setParameter("action", action);
        }

        return query.getResultList();
    }

    public AuditLog create(AuditLog entity) {
        return jpa.create(entity);
    }

    public AuditLog update(AuditLog entity) {
        return jpa.update(entity);
    }
}
