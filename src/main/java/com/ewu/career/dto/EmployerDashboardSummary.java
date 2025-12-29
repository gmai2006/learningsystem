package com.ewu.career.dto;

import java.util.List;

public record EmployerDashboardSummary(
        long activeJobsCount,
        long totalApplicantsPending,
        String companyName,
        int totalPlacements,
        long averageToHire,
        List<JobPipelineDTO> activePipelines,
        List<RecentActivityDTO> recentActivity) {}
