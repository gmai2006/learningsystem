package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.entity.StudentProfile;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
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

    /**
     * Finds a profile by the associated User ID. In this schema, the user_id is the Primary Key of
     * the student_profiles table.
     */
    public StudentProfile find(UUID userId) {
        return jpa.find(StudentProfile.class, userId);
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
}
