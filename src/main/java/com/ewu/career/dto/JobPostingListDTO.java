package com.ewu.career.dto;

import java.time.LocalDateTime;
import java.util.UUID;

public record JobPostingListDTO(
        UUID id,
        String title,
        String category,
        LocalDateTime createdAt,
        boolean isActive,
        long applicantCount) {}
