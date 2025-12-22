package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.entity.AppliedLearningExperience;
import com.ewu.career.entity.LearningType;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.persistence.TypedQuery;
import jakarta.transaction.Transactional;
import java.time.LocalDate;
import java.time.LocalDateTime;
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
                        "SELECT COUNT(e) FROM AppliedLearningExperience e WHERE e.verified ="
                                + " false",
                        Long.class)
                .getSingleResult();
    }

    /**
     * Counts experiences by specific category (e.g., INTERNSHIP, RESEARCH). Used to generate the
     * distribution charts for the 16 types.
     */
    public long countByType(String typeCode) {
        LearningType typeEnum = LearningType.valueOf(typeCode.toUpperCase());
        return jpa.getEntityManager()
                .createQuery(
                        "SELECT COUNT(e) FROM AppliedLearningExperience e WHERE e.type ="
                                + " :type",
                        Long.class)
                .setParameter("type", typeEnum)
                .getSingleResult();
    }

    public List<AppliedLearningExperience> findByJsonMetadata(String key, String value) {
        // We use the Hibernate 'function' syntax to access PostgreSQL's jsonb extraction operator
        // (->>)
        // This returns the value as a String for comparison.
        String jpql =
                "SELECT e FROM AppliedLearningExperience e WHERE"
                        + " function('jsonb_extract_path_text', e.typeSpecificData, :key) = :value";

        return jpa.getEntityManager()
                .createQuery(jpql, AppliedLearningExperience.class)
                .setParameter("key", key)
                .setParameter("value", value)
                .getResultList();
    }

    /** Specialized search for numeric comparisons within JSONB (e.g., credit_hours > 3) */
    public List<AppliedLearningExperience> findByNumericJsonMetadata(String key, int minValue) {
        // PostgreSQL requires a cast to numeric/integer for math comparisons
        // Since JPQL is strict, we use a Native Query for complex JSON math
        String sql =
                "SELECT * FROM learningsystem.applied_learning_experiences "
                        + "WHERE (type_specific_data->>:key)::int >= :minValue";

        return jpa.getEntityManager()
                .createNativeQuery(sql, AppliedLearningExperience.class)
                .setParameter("key", key)
                .setParameter("minValue", minValue)
                .getResultList();
    }

    public List<AppliedLearningExperience> findByDynamicJsonMetadata(Map<String, String> filters) {
        StringBuilder jpql =
                new StringBuilder("SELECT e FROM AppliedLearningExperience e WHERE 1=1 ");

        // Dynamically append a condition for every filter provided in the URL
        filters.keySet()
                .forEach(
                        key -> {
                            jpql.append(
                                            " AND function('jsonb_extract_path_text',"
                                                    + " e.typeSpecificData, '")
                                    .append(key) // Key name
                                    .append("') = :")
                                    .append(key); // Parameter placeholder
                        });

        TypedQuery<AppliedLearningExperience> query =
                jpa.getEntityManager()
                        .createQuery(jpql.toString(), AppliedLearningExperience.class);

        // Bind the actual values
        filters.forEach(query::setParameter);

        return query.getResultList();
    }

    public Map<String, Object> getExtendedStats() {
        Map<String, Object> stats = new HashMap<>();
        LocalDateTime now = LocalDateTime.now();

        // 1. Calculate Active Placements
        // Logic: Status is APPROVED and Current Date is between Start and End
        String activeJpql =
                "SELECT COUNT(e) FROM AppliedLearningExperience e "
                        + "WHERE e.status = 'APPROVED' "
                        + "AND e.startDate <= :today AND e.endDate >= :today";

        long activePlacements =
                jpa.getEntityManager()
                        .createQuery(activeJpql, Long.class)
                        .setParameter("today", LocalDate.now())
                        .getSingleResult();

        // 2. Calculate Completion Rate
        // Logic: (Completed) / (Completed + Approved)
        String completedJpql =
                "SELECT COUNT(e) FROM AppliedLearningExperience e WHERE e.status = 'COMPLETED'";
        String approvedJpql =
                "SELECT COUNT(e) FROM AppliedLearningExperience e WHERE e.status = 'APPROVED'";

        long completedCount =
                jpa.getEntityManager().createQuery(completedJpql, Long.class).getSingleResult();
        long approvedCount =
                jpa.getEntityManager().createQuery(approvedJpql, Long.class).getSingleResult();

        double completionRate = 0.0;
        if ((completedCount + approvedCount) > 0) {
            completionRate = ((double) completedCount / (completedCount + approvedCount)) * 100;
        }

        stats.put("activePlacements", activePlacements);
        stats.put("completionRate", String.format("%.1f%%", completionRate));

        return stats;
    }

    public AppliedLearningExperience create(AppliedLearningExperience entity) {
        return jpa.create(entity);
    }

    public AppliedLearningExperience update(AppliedLearningExperience entity) {
        return jpa.update(entity);
    }

    @Transactional
    public int deleteByUserId(UUID userId) {
        String jpql =
                "DELETE FROM AppliedLearningExperience e "
                        + "WHERE e.studentId = :userId OR e.facultyAdvisorId = :userId";

        return jpa.getEntityManager()
                .createQuery(jpql)
                .setParameter("userId", userId)
                .executeUpdate();
    }
}
