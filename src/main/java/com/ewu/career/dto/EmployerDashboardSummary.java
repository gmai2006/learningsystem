package com.ewu.career.dto;

import java.util.List;

public record EmployerDashboardSummary(
        long activeJobsCount,
        long totalApplicantsPending,
        String companyName, // Added for the header identity
        List<JobPipelineDTO> activePipelines,
        List<RecentActivityDTO> recentActivity) {}
