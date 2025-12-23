package com.ewu.career.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Data Transfer Object for job postings viewed by students. Includes isApplied flag to track
 * current user's interaction.
 */
public class JobPostingDTO {
    private UUID id;
    private String title;
    private String description;
    private String location;
    private String fundingSource;
    private LocalDate deadline;
    private LocalDateTime createdAt;
    private boolean onCampus;
    private boolean isApplied;

    //    String requirements;
    //    String salaryRange;
    //    boolean isActive;
    //    long applicantCount;

    // Constructor used for JPQL Constructor Expression
    public JobPostingDTO(
            UUID id,
            String title,
            String description,
            String location,
            String fundingSource,
            LocalDate deadline,
            LocalDateTime createdAt,
            boolean onCampus,
            boolean isApplied) {
        this.id = id;
        this.title = title;
        this.description = description;
        this.location = location;
        this.fundingSource = fundingSource;
        this.deadline = deadline;
        this.createdAt = createdAt;
        this.onCampus = onCampus;
        this.isApplied = isApplied;
    }

    // Standard Getters and Setters
    public UUID getId() {
        return id;
    }

    public String getTitle() {
        return title;
    }

    public String getDescription() {
        return description;
    }

    public String getLocation() {
        return location;
    }

    public String getFundingSource() {
        return fundingSource;
    }

    public LocalDate getDeadline() {
        return deadline;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public boolean isOnCampus() {
        return onCampus;
    }

    public boolean isApplied() {
        return isApplied;
    }

    public void setApplied(boolean applied) {
        isApplied = applied;
    }
}
