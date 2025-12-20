package com.ewu.career.entity;

import jakarta.persistence.*;
import java.util.UUID;

/** Entity representing extended profile data for Employers. Linked 1:1 with the User entity. */
@Entity
@Table(name = "employer_profiles", schema = "learningsystem")
public class EmployerProfile {

    @Id
    @Column(name = "user_id")
    private UUID userId;

    @OneToOne
    @MapsId
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "company_name", nullable = false)
    private String companyName;

    /**
     * The corporate website for the employer partner. Used for student research and administrative
     * vetting.
     */
    @Column(name = "website_url")
    private String websiteUrl;

    private String industry;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "is_approved")
    private boolean isApproved;

    // Default Constructor
    public EmployerProfile() {}

    // Getters and Setters
    public UUID getUserId() {
        return userId;
    }

    public void setUserId(UUID userId) {
        this.userId = userId;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public String getCompanyName() {
        return companyName;
    }

    public void setCompanyName(String companyName) {
        this.companyName = companyName;
    }

    public String getWebsiteUrl() {
        return websiteUrl;
    }

    public void setWebsiteUrl(String websiteUrl) {
        this.websiteUrl = websiteUrl;
    }

    public String getIndustry() {
        return industry;
    }

    public void setIndustry(String industry) {
        this.industry = industry;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public boolean isApproved() {
        return isApproved;
    }

    public void setApproved(boolean approved) {
        isApproved = approved;
    }
}
