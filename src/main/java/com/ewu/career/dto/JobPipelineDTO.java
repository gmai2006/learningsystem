package com.ewu.career.dto;

import java.util.UUID;

/** Encapsulates the hiring funnel for a specific job posting. */
public record JobPipelineDTO(
        UUID jobId,
        String title,
        long pendingCount, // Status: PENDING
        long interviewCount, // Status: INTERVIEW_SCHEDULED
        long offerCount, // Status: OFFER_EXTENDED
        int daysAgo // Days since the job was posted
        ) {}
