package com.ewu.career.service;

import com.ewu.career.dao.StudentProfileDao;
import com.ewu.career.dto.StudentProfileDTO;
import com.ewu.career.entity.StudentProfile;
import com.ewu.career.entity.User;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import java.util.UUID;

@Stateless
@Named("StudentProfileService")
public class StudentProfileService {

    @Inject private StudentProfileDao profileDao;

    public StudentProfileDTO findByUserId(UUID userId) {
        return profileDao.findByUserId(userId);
    }

    public StudentProfile updateProfile(User actor, StudentProfile updatedProfile) {
        // Students can only update their own profile; Staff have full access.
        boolean isOwner = actor.getId().equals(updatedProfile.getUserId());
        boolean isStaff = actor.getRole().name().equals("STAFF");

        if (!isOwner && !isStaff) {
            throw new SecurityException("Forbidden: Unauthorized to update this student profile.");
        }

        // Ensure only Staff can modify Work Study eligibility manually
        if (!isStaff) {
            StudentProfileDTO existing = profileDao.findByUserId(updatedProfile.getUserId());
            updatedProfile.setWorkStudyEligible(existing.workStudyEligible());
        }

        return profileDao.update(updatedProfile);
    }
}
