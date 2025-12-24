package com.ewu.career.dto;

import java.util.UUID;

public record EmployerCandidateProfileDTO(
        UUID applicationId,
        String studentName,
        String email,
        String major,
        Double gpa,
        Integer graduationYear, // Updated to match your schema
        String bio,
        String resumeUrl,
        String portfolioUrl,
        String linkedinUrl,
        String githubUrl,
        String profilePicture,
        String status,
        String jobTitle) {}
