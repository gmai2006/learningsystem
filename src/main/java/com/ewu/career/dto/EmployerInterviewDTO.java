package com.ewu.career.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record EmployerInterviewDTO(
        UUID id,
        UUID applicationId,
        String studentName,
        String studentProfilePicture,
        String jobTitle,
        LocalDateTime scheduledAt,
        boolean isVirtual,
        String meetingUrl,
        String locationNotes) {}
