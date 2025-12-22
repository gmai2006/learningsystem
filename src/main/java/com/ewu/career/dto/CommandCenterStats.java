package com.ewu.career.dto;

import java.util.List;
import java.util.Map;

public class CommandCenterStats {
    // KPI Metrics
    public long activeStudents;
    public long pendingJobApprovals;
    public long unverifiedExperiences;
    public long employerPartners;
    public long newEmployerPartners;
    public long activePlacements;
    public String completionRate;

    // Distribution of the 16 Applied Learning Types
    public Map<String, Long> experienceDistribution;

    // Recent Activity (System Pulse)
    public List<ActivityLog> recentActivity;

    public static class ActivityLog {
        public String user;
        public String action;
        public String timeLabel; // e.g., "2m ago"
        public String type; // e.g., "JOB", "LEARNING", "SYSTEM"
    }
}
