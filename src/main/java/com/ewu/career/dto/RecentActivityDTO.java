package com.ewu.career.dto;

import java.time.LocalDateTime;

/** Represents a single event in the employer's recruitment timeline. */
public record RecentActivityDTO(
        String message, // e.g., "Swoop Eagle applied to 'Web Developer'"
        String type, // e.g., "APPLICATION", "INTERVIEW", "HIRE"
        LocalDateTime timestamp,
        String timeAgo // Pre-formatted string like "2 hours ago"
        ) {}
