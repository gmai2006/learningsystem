package com.ewu.career.dto;

import java.time.LocalDateTime;

/**
 * Encapsulates the details of an employer viewing a student's profile. Used for the Student Data
 * Access History dashboard.
 */
public record ProfileAccessLogDTO(
        String companyName, LocalDateTime accessedAt, String accessContext) {}
