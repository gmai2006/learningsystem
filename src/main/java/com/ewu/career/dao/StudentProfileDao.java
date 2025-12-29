package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.dto.StudentProfileDTO;
import com.ewu.career.entity.StudentProfile;
import com.ewu.career.entity.User;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.transaction.Transactional;
import java.util.HashSet;
import java.util.List;
import java.util.UUID;

/**
 * DAO for managing Student-specific metadata (GPA, Work Study, Portfolio). Supports the 1:1
 * relationship with the primary User entity.
 */
@Stateless
@Named("StudentProfileDao")
public class StudentProfileDao {

    @Inject
    @Named("DefaultJpaDao")
    private JpaDao jpa;

    /** Retrieves the combined profile from the database view. */
    public StudentProfileDTO findByUserId(UUID userId) {
        // 1. Query the View for combined user and profile data
        Object[] result =
                (Object[])
                        jpa.getEntityManager()
                                .createNativeQuery(
                                        "SELECT user_id, first_name, last_name, email, major, gpa,"
                                            + " work_study_eligible, graduation_year, bio,"
                                            + " resume_url, portfolio_url, linkedin_url,"
                                            + " github_url, profile_picture_base64,"
                                            + " is_ferpa_restricted FROM"
                                            + " learningsystem.vw_student_profiles WHERE user_id ="
                                            + " :uid")
                                .setParameter("uid", userId)
                                .getSingleResult();

        if (result == null) return null;

        // 2. Fetch skills list separately in Java (as requested)
        List<String> skillList =
                jpa.getEntityManager()
                        .createNativeQuery(
                                "SELECT skill_name FROM learningsystem.student_skills WHERE user_id"
                                        + " = :uid")
                        .setParameter("uid", userId)
                        .getResultList();

        Double gpaValue = null;
        if (result[5] != null) {
            if (result[5] instanceof java.math.BigDecimal) {
                gpaValue = ((java.math.BigDecimal) result[5]).doubleValue();
            } else if (result[5] instanceof Number) {
                gpaValue = ((Number) result[5]).doubleValue();
            }
        }

        // 3. Map the raw Object array from the view to the DTO
        return new StudentProfileDTO(
                (UUID) result[0],
                (String) result[1],
                (String) result[2],
                (String) result[3],
                (String) result[4],
                gpaValue,
                (Boolean) result[6],
                (Integer) result[7],
                (String) result[8],
                (String) result[9],
                (String) result[10],
                (String) result[11],
                (String) result[12],
                new HashSet<>(skillList),
                (String) result[13],
                (Boolean) result[14]);
    }

    /** Specifically updates the skills list by clearing and re-inserting. */
    @Transactional
    public void updateSkills(UUID userId, List<String> skills) {
        // 1. Remove existing skills
        jpa.getEntityManager()
                .createNativeQuery("DELETE FROM learningsystem.student_skills WHERE user_id = :uid")
                .setParameter("uid", userId)
                .executeUpdate();

        // 2. Insert new skills
        for (String skill : skills) {
            jpa.getEntityManager()
                    .createNativeQuery(
                            "INSERT INTO learningsystem.student_skills (user_id, skill_name) VALUES"
                                    + " (:uid, :skill)")
                    .setParameter("uid", userId)
                    .setParameter("skill", skill)
                    .executeUpdate();
        }
    }

    @Transactional
    public void updateStudentProfile(StudentProfileDTO dto, User actor) {
        // 1. Fetch the current managed entity from the DB
        StudentProfile existingEntity =
                jpa.getEntityManager().find(StudentProfile.class, actor.getId());

        if (existingEntity == null) {
            // Optional: Handle case where profile doesn't exist yet
            existingEntity = new StudentProfile();
            existingEntity.setUserId(dto.userId());
        }

        // 2. Map the updated fields from the DTO onto the Entity
        mapDtoToEntity(dto, existingEntity);

        // 3. Save/Merge the updated entity
        jpa.getEntityManager().merge(existingEntity);
    }

    /**
     * Creates a new profile record. Used by the BannerSyncConsumer when a new student is first
     * imported.
     */
    public StudentProfile create(StudentProfile entity) {
        return jpa.create(entity);
    }

    /**
     * Updates student academic data or eligibility status. Essential for real-time synchronization
     * with Banner updates.
     */
    public StudentProfile update(StudentProfile entity) {
        return jpa.update(entity);
    }

    /** Removes a student profile. */
    public void delete(UUID userId) {
        jpa.delete(StudentProfile.class, userId);
    }

    /**
     * Maps DTO data to an existing Entity for database updates. This preserves the JPA lifecycle
     * and ensures we don't create duplicate records.
     */
    public StudentProfile mapDtoToEntity(StudentProfileDTO dto, StudentProfile entity) {
        if (dto == null || entity == null) {
            return entity;
        }

        // Academic & Personal Details
        entity.setMajor(dto.major());
        entity.setGraduationYear(dto.graduationYear());
        entity.setBio(dto.bio());

        // GPA Conversion (Handling BigDecimal to Double if necessary)
        if (dto.gpa() != null) {
            entity.setGpa(dto.gpa());
        }

        // Eligibility & Professional Links
        entity.setWorkStudyEligible(dto.workStudyEligible());
        entity.setResumeUrl(dto.resumeUrl());
        entity.setPortfolioUrl(dto.portfolioUrl());
        entity.setLinkedinUrl(dto.linkedinUrl());
        entity.setGithubUrl(dto.githubUrl());
        entity.setProfilePictureBase64(dto.profilePictureBase64());

        // Skills are handled via the Set mapping in Java
        if (dto.skills() != null) {
            entity.setSkills(new HashSet<>(dto.skills()));
        }

        return entity;
    }
}
