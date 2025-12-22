package com.ewu.career.entity;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.UUID;
import org.hibernate.annotations.JdbcType;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.dialect.PostgreSQLEnumJdbcType;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "applied_learning_experiences")
public class AppliedLearningExperience {

    @Id @GeneratedValue private UUID id;

    @Column(name = "student_id", nullable = false)
    private UUID studentId;

    @Column(name = "faculty_advisor_id")
    private UUID facultyAdvisorId;

    @Enumerated(EnumType.STRING)
    @JdbcType(PostgreSQLEnumJdbcType.class)
    @Column(nullable = false, name = "type", columnDefinition = "learning_type")
    private LearningType type;

    @Column(nullable = false)
    private String title;

    @Column(name = "organization_name")
    private String organizationName;

    @Column(length = 50)
    private String status = "DRAFT"; // DRAFT, PENDING, APPROVED, COMPLETED

    @Column(name = "start_date")
    private LocalDate startDate;

    @Column(name = "end_date")
    private LocalDate endDate;

    @Column(name = "canvas_course_id", length = 50)
    private String canvasCourseId;

    // --- JSONB Mapping for 16 Types ---
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "type_specific_data", columnDefinition = "jsonb")
    private Map<String, Object> typeSpecificData;

    @Column(name = "is_verified")
    private boolean verified = false;

    @Column(name = "verified_at")
    private LocalDateTime verifiedAt;

    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();

    // Standard Getters and Setters
    public Map<String, Object> getTypeSpecificData() {
        return typeSpecificData;
    }

    public void setTypeSpecificData(Map<String, Object> data) {
        this.typeSpecificData = data;
    }

    public boolean isVerified() {
        return verified;
    }

    public void setVerified(boolean verified) {
        this.verified = verified;
    }

    public LocalDateTime getVerifiedAt() {
        return verifiedAt;
    }

    public void setVerifiedAt(LocalDateTime verifiedAt) {
        this.verifiedAt = verifiedAt;
    }

    public UUID getStudentId() {
        return studentId;
    }

    public void setStudentId(UUID studentId) {
        this.studentId = studentId;
    }

    public UUID getFacultyAdvisorId() {
        return facultyAdvisorId;
    }

    public void setFacultyAdvisorId(UUID facultyAdvisorId) {
        this.facultyAdvisorId = facultyAdvisorId;
    }

    public LearningType getType() {
        return type;
    }

    public void setType(LearningType type) {
        this.type = type;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getOrganizationName() {
        return organizationName;
    }

    public void setOrganizationName(String organizationName) {
        this.organizationName = organizationName;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDate getStartDate() {
        return startDate;
    }

    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }

    public LocalDate getEndDate() {
        return endDate;
    }

    public void setEndDate(LocalDate endDate) {
        this.endDate = endDate;
    }

    public String getCanvasCourseId() {
        return canvasCourseId;
    }

    public void setCanvasCourseId(String canvasCourseId) {
        this.canvasCourseId = canvasCourseId;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public UUID getId() {
        return id;
    }
}
