package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.entity.AppliedLearningExperience;
import com.ewu.career.entity.LearningType;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Stateless
@Named("AppliedLearningExperienceDao")
public class AppliedLearningExperienceDao {

    @Inject
    @Named("DefaultJpaDao")
    private JpaDao jpa;

    public AppliedLearningExperience find(UUID id) {
        return jpa.find(AppliedLearningExperience.class, id);
    }

    /** Retrieves all experiences for a specific student. */
    public List<AppliedLearningExperience> findByStudent(UUID studentId) {
        String query = "SELECT e FROM AppliedLearningExperience e WHERE e.studentId = :studentId";
        Map<String, Object> params = new HashMap<>();
        params.put("studentId", studentId);
        return jpa.selectAllWithParameters(query, AppliedLearningExperience.class, params);
    }

    /** Filters by one of the 16 distinct learning types. */
    public List<AppliedLearningExperience> findByType(LearningType type) {
        String query = "SELECT e FROM AppliedLearningExperience e WHERE e.type = :type";
        Map<String, Object> params = new HashMap<>();
        params.put("type", type);
        return jpa.selectAllWithParameters(query, AppliedLearningExperience.class, params);
    }

    /** Supports real-time visualization by fetching experiences tied to Canvas courses. */
    public List<AppliedLearningExperience> findByCanvasCourse(String canvasCourseId) {
        String query =
                "SELECT e FROM AppliedLearningExperience e WHERE e.canvasCourseId ="
                        + " :canvasCourseId";
        Map<String, Object> params = new HashMap<>();
        params.put("canvasCourseId", canvasCourseId);
        return jpa.selectAllWithParameters(query, AppliedLearningExperience.class, params);
    }

    /**
     * Counts experiences awaiting supervisor or staff verification. Fulfills the "Unverified
     * Experiences" KPI.
     */
    public long countUnverified() {
        return jpa.getEntityManager()
                .createQuery(
                        "SELECT COUNT(e) FROM AppliedLearningExperience e WHERE e.isVerified ="
                                + " false",
                        Long.class)
                .getSingleResult();
    }

    /**
     * Counts experiences by specific category (e.g., INTERNSHIP, RESEARCH). Used to generate the
     * distribution charts for the 16 types.
     */
    public long countByType(String typeCode) {
        return jpa.getEntityManager()
                .createQuery(
                        "SELECT COUNT(e) FROM AppliedLearningExperience e WHERE e.experienceType ="
                                + " :type",
                        Long.class)
                .setParameter("type", typeCode)
                .getSingleResult();
    }

    public AppliedLearningExperience create(AppliedLearningExperience entity) {
        return jpa.create(entity);
    }

    public AppliedLearningExperience update(AppliedLearningExperience entity) {
        return jpa.update(entity);
    }
}
