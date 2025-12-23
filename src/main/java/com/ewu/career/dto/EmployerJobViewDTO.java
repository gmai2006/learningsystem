package com.ewu.career.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

public record EmployerJobViewDTO(
        UUID id,
        String title,
        String description,
        String requirements,
        String category,
        String location,
        String salaryRange,
        LocalDateTime createdAt,
        boolean isActive,
        long applicantCount,
        String fundingSource,
        LocalDate deadline) {}
