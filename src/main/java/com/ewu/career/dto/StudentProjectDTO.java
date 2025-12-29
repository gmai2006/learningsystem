package com.ewu.career.dto;

import java.math.BigDecimal;
import java.util.UUID;

/** Aggregated view of a student's involvement in a specific project. */
public record StudentProjectDTO(
        UUID id,
        String title,
        String organizationName,
        String status,
        BigDecimal totalHoursLogged) {}
