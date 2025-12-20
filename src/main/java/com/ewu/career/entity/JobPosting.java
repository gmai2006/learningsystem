package com.ewu.career.entity;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.util.UUID;

/**
 * Entity representing job opportunities, internships, and student employment. Maps to the updated
 * job_postings table.
 */
@Entity
@Table(name = "job_postings", schema = "learningsystem")
public class JobPosting {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    /** Link to the Employer or Staff user who created the posting. */
    @Column(name = "employer_id", nullable = false)
    private UUID employerId;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    /** Geographic location or specific EWU campus site for the position. */
    private String location;

    /** Funding source (e.g., 'WORK_STUDY', 'NON_WORK_STUDY'). */
    @Column(name = "funding_source")
    private String fundingSource;

    @Column(name = "is_on_campus")
    private boolean isOnCampus;

    private LocalDate deadline;

    @Column(name = "is_active")
    private boolean isActive = true;

    // Default Constructor
    public JobPosting() {}

    // Getters and Setters
    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getEmployerId() {
        return employerId;
    }

    public void setEmployerId(UUID employerId) {
        this.employerId = employerId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public String getFundingSource() {
        return fundingSource;
    }

    public void setFundingSource(String fundingSource) {
        this.fundingSource = fundingSource;
    }

    public boolean isOnCampus() {
        return isOnCampus;
    }

    public void setOnCampus(boolean onCampus) {
        isOnCampus = onCampus;
    }

    public LocalDate getDeadline() {
        return deadline;
    }

    public void setDeadline(LocalDate deadline) {
        this.deadline = deadline;
    }

    public boolean isActive() {
        return isActive;
    }

    public void setActive(boolean active) {
        isActive = active;
    }
}
