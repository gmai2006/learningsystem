package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.dto.ExperienceMilestone;
import com.ewu.career.dto.StudentDashboardSummary;
import com.ewu.career.entity.AppliedLearningExperience;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@ApplicationScoped
public class StudentDashboardDao {

    @Inject
    @Named("DefaultJpaDao")
    private JpaDao jpa;

    @Inject private LearningDao learningDao;

    public StudentDashboardSummary getSummary(UUID studentId) {
        LocalDateTime oneWeekAgo = LocalDateTime.now().minusDays(7);

        // 1. Total Active Applications
        Long totalActive =
                jpa.getEntityManager()
                        .createQuery(
                                "SELECT COUNT(a) FROM JobApplication a WHERE a.studentId = :sid AND"
                                        + " a.status != 'REJECTED'",
                                Long.class)
                        .setParameter("sid", studentId)
                        .getSingleResult();

        // 2. NEW Active Postings/Applications
        Long newActive =
                jpa.getEntityManager()
                        .createQuery(
                                "SELECT COUNT(a) FROM JobPosting a WHERE a.employerId = :sid "
                                        + "AND a.isActive = true AND a.createdAt >= :since",
                                Long.class)
                        .setParameter("sid", studentId)
                        .setParameter("since", oneWeekAgo)
                        .getSingleResult();

        // 3. Summing Verified Hours from JSONB
        Number verifiedHoursResult =
                (Number)
                        jpa.getEntityManager()
                                .createNativeQuery(
                                        "SELECT"
                                            + " COALESCE(SUM((type_specific_data->>'total_hours')::int),"
                                            + " 0) FROM learningsystem.applied_learning_experiences"
                                            + " WHERE student_id = :sid AND is_verified = true")
                                .setParameter("sid", studentId)
                                .getSingleResult();

        long totalVerifiedHours = verifiedHoursResult.longValue();

        // 4. Milestone Provider: Fetch 3 most recent experiences
        List<AppliedLearningExperience> recentExps =
                jpa.getEntityManager()
                        .createQuery(
                                "SELECT e FROM AppliedLearningExperience e WHERE e.studentId = :sid"
                                        + " ORDER BY e.createdAt DESC",
                                AppliedLearningExperience.class)
                        .setParameter("sid", studentId)
                        .setMaxResults(3)
                        .getResultList();

        List<ExperienceMilestone> milestones =
                recentExps.stream().map(this::mapToMilestone).toList();

        // 5. Count Pending Verifications
        Long pending =
                jpa.getEntityManager()
                        .createQuery(
                                "SELECT COUNT(e) FROM AppliedLearningExperience e WHERE e.studentId"
                                        + " = :sid AND e.verified = false",
                                Long.class)
                        .setParameter("sid", studentId)
                        .getSingleResult();

        int readiness = learningDao.getReadinessScore(studentId);

        // Calculate Tier based on readiness percentage
        String tierName;
        String tierColor;

        if (readiness >= 90) {
            tierName = "Career Ready Elite";
            tierColor = "#D4AF37"; // Gold
        } else if (readiness >= 60) {
            tierName = "Industry Professional";
            tierColor = "#A10022"; // EWU Red
        } else if (readiness >= 30) {
            tierName = "Emerging Talent";
            tierColor = "#4A90E2"; // Blue
        } else {
            tierName = "Career Explorer";
            tierColor = "#9B9B9B"; // Gray
        }

        return new StudentDashboardSummary(
                totalActive,
                newActive,
                totalVerifiedHours,
                pending,
                readiness,
                tierName,
                tierColor,
                milestones);
    }

    public Map<String, Object> getStudentVolunteerImpact(UUID studentId) {
        String sql =
                "SELECT COALESCE(SUM(j.service_hours), 0), COUNT(a.id) "
                        + "FROM learningsystem.job_applications a "
                        + "JOIN learningsystem.job_postings j ON a.job_id = j.id "
                        + "WHERE a.student_id = :sid AND a.status = 'COMPLETED'";

        Object[] result =
                (Object[])
                        jpa.getEntityManager()
                                .createNativeQuery(sql)
                                .setParameter("sid", studentId)
                                .getSingleResult();

        return Map.of(
                "totalHours", ((Number) result[0]).intValue(),
                "projectCount", ((Number) result[1]).longValue());
    }

    private ExperienceMilestone mapToMilestone(AppliedLearningExperience e) {
        int progress = 0;
        if (e.isVerified()) progress = 100;
        else if ("APPROVED".equals(e.getStatus())) progress = 75;
        else if ("PENDING".equals(e.getStatus())) progress = 25;

        return new ExperienceMilestone(
                e.getTitle(),
                e.getType().toString(),
                progress,
                e.getStatus(),
                e.getOrganizationName());
    }
}
