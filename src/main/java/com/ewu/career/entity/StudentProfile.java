package com.ewu.career.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.util.UUID;

@Entity
@Table(name = "student_profiles")
public class StudentProfile {

    // PK is also the FK to User table
    @Id
    @Column(name = "user_id")
    private UUID userId;

    private String major;

    @Column(precision = 3, scale = 2)
    private BigDecimal gpa;

    @Column(name = "work_study_eligible")
    private Boolean workStudyEligible;

    @Column(name = "graduation_year")
    private Integer graduationYear;

    @Column(name = "resume_url")
    private String resumeUrl;

    @Column(name = "portfolio_url")
    private String portfolioUrl;

    public StudentProfile() {}

    // Getters and Setters
    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public String getMajor() {
        return major;
    }

    public void setMajor(String major) {
        this.major = major;
    }

    public BigDecimal getGpa() {
        return gpa;
    }

    public void setGpa(BigDecimal gpa) {
        this.gpa = gpa;
    }

    public Boolean getIsWorkStudyEligible() {
        return workStudyEligible;
    }

    public void setIsWorkStudyEligible(Boolean workStudyEligible) {
        this.workStudyEligible = workStudyEligible;
    }

    public Integer getGraduationYear() {
        return graduationYear;
    }

    public void setGraduationYear(Integer graduationYear) {
        this.graduationYear = graduationYear;
    }

    public String getResumeUrl() {
        return resumeUrl;
    }

    public void setResumeUrl(String resumeUrl) {
        this.resumeUrl = resumeUrl;
    }

    public String getPortfolioUrl() {
        return portfolioUrl;
    }

    public void setPortfolioUrl(String portfolioUrl) {
        this.portfolioUrl = portfolioUrl;
    }
}
