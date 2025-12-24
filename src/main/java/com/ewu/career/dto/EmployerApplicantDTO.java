package com.ewu.career.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record EmployerApplicantDTO(
        UUID applicationId,
        UUID studentId,
        String studentName,
        String email,
        String major,
        Double gpa,
        String jobTitle,
        String status, // PENDING, INTERVIEW_SCHEDULED, OFFER_EXTENDED, REJECTED
        LocalDateTime appliedAt,
        String timeAgo,
        String profilePictureBase64) {}
