package com.ewu.career.dto;

import java.util.List;

public record StudentDashboardSummary(
        long totalActiveApplications,
        long newApplicationsLastWeek,
        long totalVerifiedHours,
        long pendingVerifications,
        int readinessScore,
        String tierName, // NEW: e.g., "Industry Professional"
        String tierColor, // NEW: hex code or CSS class
        List<ExperienceMilestone> recentMilestones) {}
