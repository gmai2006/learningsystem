package com.ewu.career.entity;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import org.hibernate.annotations.Immutable;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

/**
 * Immutable entity mapping to the 'v_job_oversight' database view. Supports both Staff Oversight
 * and Student Job Board views via LEFT JOIN logic.
 */
@Entity
@Immutable
@Table(name = "v_job_oversight", schema = "learningsystem")
public class JobOversightView {

    // --- Posting Details ---
    @Id
    @Column(name = "job_id")
    private UUID jobId;

    @Column(name = "job_title")
    private String jobTitle;

    @Column(name = "category")
    private String category;

    @Column(name = "location")
    private String location;

    @Column(name = "job_description", columnDefinition = "TEXT")
    private String jobDescription;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "job_requirements", columnDefinition = "jsonb")
    private List<String> jobRequirements;

    @Column(name = "funding_source")
    private String fundingSource;

    @Column(name = "is_on_campus")
    private Boolean isOnCampus;

    @Column(name = "salary_range")
    private String salaryRange;

    @Column(name = "service_hours")
    private Integer serviceHours;

    @Column(name = "deadline")
    private LocalDate deadline;

    @Column(name = "is_active")
    private Boolean isActive;

    @Column(name = "job_created_at")
    private LocalDateTime jobCreatedAt;

    @Column(name = "job_deleted_at")
    private LocalDateTime jobDeletedAt;

    // --- Employer Details ---
    @Column(name = "employer_id")
    private UUID employerId;

    @Column(name = "company_name")
    private String companyName;

    @Column(name = "company_website")
    private String companyWebsite;

    // --- Application Details (Nullable due to LEFT JOIN) ---
    @Column(name = "application_id")
    private UUID applicationId;

    @Column(name = "student_id")
    private UUID studentId;

    @Column(name = "application_status")
    private String applicationStatus;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "learning_objectives", columnDefinition = "jsonb")
    private List<String> learningObjectives;

    @Column(name = "student_notes", columnDefinition = "TEXT")
    private String studentNotes;

    @Column(name = "applied_at")
    private LocalDateTime appliedAt;

    // --- Student Details ---
    @Column(name = "student_name")
    private String studentName;

    @Column(name = "student_email")
    private String studentEmail;

    // --- Constructor ---
    protected JobOversightView() {}

    // --- Getters ---
    public UUID getJobId() {
        return jobId;
    }

    public String getJobTitle() {
        return jobTitle;
    }

    public String getCategory() {
        return category;
    }

    public String getLocation() {
        return location;
    }

    public List<String> getJobRequirements() {
        return jobRequirements;
    }

    public String getFundingSource() {
        return fundingSource;
    }

    public Boolean getIsOnCampus() {
        return isOnCampus;
    }

    public String getSalaryRange() {
        return salaryRange;
    }

    public Integer getServiceHours() {
        return serviceHours;
    }

    public LocalDate getDeadline() {
        return deadline;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public LocalDateTime getJobCreatedAt() {
        return jobCreatedAt;
    }

    public LocalDateTime getJobDeletedAt() {
        return jobDeletedAt;
    }

    public UUID getEmployerId() {
        return employerId;
    }

    public String getCompanyName() {
        return companyName;
    }

    public String getCompanyWebsite() {
        return companyWebsite;
    }

    public UUID getApplicationId() {
        return applicationId;
    }

    public UUID getStudentId() {
        return studentId;
    }

    public String getApplicationStatus() {
        return applicationStatus;
    }

    public List<String> getLearningObjectives() {
        return learningObjectives;
    }

    public String getStudentNotes() {
        return studentNotes;
    }

    public LocalDateTime getAppliedAt() {
        return appliedAt;
    }

    public String getStudentName() {
        return studentName;
    }

    public String getStudentEmail() {
        return studentEmail;
    }

    public String getJobDescription() {
        return jobDescription;
    }

    public void setJobDescription(String jobDescription) {
        this.jobDescription = jobDescription;
    }
}
