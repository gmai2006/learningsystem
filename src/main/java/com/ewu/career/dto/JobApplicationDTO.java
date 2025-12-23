package com.ewu.career.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record JobApplicationDTO(
        UUID id,
        UUID jobId,
        String jobTitle,
        String location,
        String status,
        String notes,
        LocalDateTime createdAt,
        boolean isJobActive,
        String description, // Added for Detail View
        String fundingSource // Added for Detail View
        ) {}
