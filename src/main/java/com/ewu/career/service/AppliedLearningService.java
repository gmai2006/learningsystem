package com.ewu.career.service;

import com.ewu.career.dao.AppliedLearningExperienceDao;
import com.ewu.career.entity.AppliedLearningExperience;
import com.ewu.career.entity.LearningType;
import com.ewu.career.entity.User;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Stateless
@Named("AppliedLearningService")
public class AppliedLearningService {
    // Only internal staff and faculty can manage all records
    private static final Set<String> ADMIN_ROLES = Set.of("STAFF", "FACULTY");

    @Inject private AppliedLearningExperienceDao experienceDao;

    public AppliedLearningExperience find(UUID id) {
        return experienceDao.find(id);
    }

    public List<AppliedLearningExperience> findByStudent(UUID studentId) {
        return experienceDao.findByStudent(studentId);
    }

    /**
     * Filters experiences by one of the 16 distinct learning types. Supports the requirement for
     * simultaneous data extraction and reporting.
     */
    public List<AppliedLearningExperience> findByType(LearningType type) {
        return experienceDao.findByType(type);
    }

    public AppliedLearningExperience create(User actor, AppliedLearningExperience experience) {
        // Students can create their own; Staff/Faculty can create for anyone
        if (actor != null
                && !actor.getRole().name().equals("STUDENT")
                && !ADMIN_ROLES.contains(actor.getRole().name())) {
            throw new SecurityException("Forbidden: Unauthorized to create experience");
        }
        return experienceDao.create(experience);
    }

    public AppliedLearningExperience update(User actor, AppliedLearningExperience experience) {
        // Logic to verify ownership or administrative rights
        boolean isOwner = actor != null && actor.getId().equals(experience.getStudentId());
        boolean isAdmin = actor != null && ADMIN_ROLES.contains(actor.getRole().name());

        if (!isOwner && !isAdmin) {
            throw new SecurityException("Forbidden: Insufficient permissions to update");
        }
        return experienceDao.update(experience);
    }
}
