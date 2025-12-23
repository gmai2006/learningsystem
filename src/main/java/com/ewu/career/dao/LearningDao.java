package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.entity.LearningModule;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class LearningDao {

    @Inject
    @Named("DefaultJpaDao")
    private JpaDao jpa;

    /** Fetches all active modules. */
    public List<LearningModule> findAllActive() {
        return jpa.getEntityManager()
                .createQuery(
                        "SELECT m FROM LearningModule m WHERE m.isActive = true",
                        LearningModule.class)
                .getResultList();
    }

    /** Records a module completion for a student. */
    @Transactional
    public void markAsComplete(UUID studentId, UUID moduleId) {
        jpa.getEntityManager()
                .createNativeQuery(
                        "INSERT INTO learningsystem.student_module_completions (student_id,"
                                + " module_id) VALUES (:sid, :mid) ON CONFLICT DO NOTHING")
                .setParameter("sid", studentId)
                .setParameter("mid", moduleId)
                .executeUpdate();
    }

    /** Returns IDs of modules completed by the student. */
    public List<UUID> getCompletedModuleIds(UUID studentId) {
        return jpa.getEntityManager()
                .createNativeQuery(
                        "SELECT module_id FROM learningsystem.student_module_completions WHERE"
                                + " student_id = :sid")
                .setParameter("sid", studentId)
                .getResultList();
    }

    /** Calculates readiness percentage (Completed / Total Active). */
    /**
     * Calculates a weighted readiness score. (Sum of weights of completed modules / Sum of weights
     * of all active modules) * 100
     */
    public int getReadinessScore(UUID studentId) {
        // 1. Calculate Total Possible Points from all active modules
        Number totalPossibleResult =
                (Number)
                        jpa.getEntityManager()
                                .createQuery(
                                        "SELECT SUM(m.weight) FROM LearningModule m WHERE"
                                                + " m.isActive = true")
                                .getSingleResult();

        long totalPossible = (totalPossibleResult != null) ? totalPossibleResult.longValue() : 0;
        if (totalPossible == 0) return 0;

        // 2. Calculate Earned Points from completed modules
        // We join the modules table with the completions table
        Number earnedResult =
                (Number)
                        jpa.getEntityManager()
                                .createNativeQuery(
                                        "SELECT SUM(m.weight) FROM learningsystem.learning_modules"
                                            + " m JOIN learningsystem.student_module_completions c"
                                            + " ON m.id = c.module_id WHERE c.student_id = :sid AND"
                                            + " m.is_active = true")
                                .setParameter("sid", studentId)
                                .getSingleResult();

        long earned = (earnedResult != null) ? earnedResult.longValue() : 0;

        // 3. Return percentage as an integer
        return (int) ((earned * 100) / totalPossible);
    }
}
