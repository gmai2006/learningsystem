package com.ewu.career.service;

import com.ewu.career.dao.*;
import com.ewu.career.dto.CommandCenterStats;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@ApplicationScoped
public class DashboardService {

    @Inject private UserDao userDao;
    @Inject private JobPostingDao jobDao;
    @Inject private AuditLogDao auditLogDao;
    @Inject private AppliedLearningExperienceDao experienceDao;

    public CommandCenterStats getAggregatedStats() {
        CommandCenterStats stats = new CommandCenterStats();

        // 1. Fetch KPI Metrics
        stats.activeStudents = userDao.countByRole("STUDENT");
        stats.pendingJobApprovals = jobDao.countPending();
        stats.unverifiedExperiences = experienceDao.countUnverified();
        stats.employerPartners = userDao.countByRole("EMPLOYER");

        // 2. Map Applied Learning Distribution (Sample logic for the 16 types)
        Map<String, Long> dist = new HashMap<>();
        dist.put("Internships", experienceDao.countByType("INTERNSHIP"));
        dist.put("Research", experienceDao.countByType("RESEARCH"));
        dist.put("Study Abroad", experienceDao.countByType("STUDY_ABROAD"));
        stats.experienceDistribution = dist;

        // 3. Fetch System Pulse (Last 5-10 events)
        stats.recentActivity = getRecentAuditLogs();

        return stats;
    }

    public List<CommandCenterStats.ActivityLog> getRecentAuditLogs() {
        return auditLogDao.findRecent(5).stream()
                .map(
                        entry -> {
                            CommandCenterStats.ActivityLog log =
                                    new CommandCenterStats.ActivityLog();
                            log.user = entry.getActorName();
                            log.action = entry.getAction();
                            log.type = entry.getTargetType();
                            log.timeLabel = formatTimeAgo(entry.getCreatedAt());
                            return log;
                        })
                .toList();
    }

    /** Helper to convert timestamps into human-readable labels like "2m ago" */
    private String formatTimeAgo(LocalDateTime dateTime) {
        long minutes = Duration.between(dateTime, LocalDateTime.now()).toMinutes();
        if (minutes < 1) return "Just now";
        if (minutes < 60) return minutes + "m ago";
        if (minutes < 1440) return (minutes / 60) + "h ago";
        return (minutes / 1440) + "d ago";
    }
}
