package com.ewu.career.entity;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.annotations.UpdateTimestamp;
import org.hibernate.type.SqlTypes;

@Entity
@Table(name = "applied_learning_experiences")
public class AppliedLearningExperience {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @Column(name = "id", updatable = false, nullable = false)
    private UUID id;

    // Manual foreign key relationship
    @Column(name = "student_id", nullable = false)
    private UUID studentId;

    @Column(name = "faculty_advisor_id")
    private UUID facultyAdvisorId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private LearningType type;

    @Column(nullable = false)
    private String title;

    @Column(name = "organization_name")
    private String organizationName;

    @Column(name = "status")
    private String status = "DRAFT";

    @Column(name = "start_date")
    private LocalDate startDate;

    @Column(name = "end_date")
    private LocalDate endDate;

    @Column(name = "canvas_course_id")
    private String canvasCourseId;

    /**
     * Standard Hibernate 6 JSON mapping. Maps to 'jsonb' in PostgreSQL automatically when dialect
     * is configured correctly.
     */
    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "type_specific_data", columnDefinition = "jsonb")
    private Map<String, Object> typeSpecificData;

    @CreationTimestamp
    @Column(name = "created_at", updatable = false)
    private LocalDateTime createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    public AppliedLearningExperience() {}

    // Getters and Setters
    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
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

    public Map<String, Object> getTypeSpecificData() {
        return typeSpecificData;
    }

    public void setTypeSpecificData(Map<String, Object> typeSpecificData) {
        this.typeSpecificData = typeSpecificData;
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

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        AppliedLearningExperience that = (AppliedLearningExperience) o;
        return Objects.equals(id, that.id);
    }

    @Override
    public int hashCode() {
        return Objects.hash(id);
    }
}
