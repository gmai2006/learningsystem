package com.ewu.career.dto;

import java.util.Set;
import java.util.UUID;

/** Encapsulates both identity and career data for a student. */
public record StudentProfileDTO(
        UUID userId,
        String firstName,
        String lastName,
        String email,
        String major,
        Double gpa,
        boolean workStudyEligible,
        Integer graduationYear,
        String bio,
        String resumeUrl,
        String portfolioUrl,
        String linkedinUrl,
        String githubUrl,
        Set<String> skills, // Populated separately in the DAO
        String profilePictureBase64) {}
