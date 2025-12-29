package com.ewu.career.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Entity representing Career Fairs, Workshops, and Information Sessions. Supports fee management
 * via TouchNet integration and hybrid location logistics.
 */
@Entity
@Table(name = "events", schema = "learningsystem")
public class Event {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    @Column(name = "organizer_id")
    private UUID organizerId;

    private String title;
    private String description;
    private String type;
    private String location;

    @Column(name = "is_virtual")
    private boolean isVirtual;

    @Column(name = "meeting_link")
    private String meetingLink;

    @Column(name = "start_time")
    private LocalDateTime startTime;

    @Column(name = "end_time")
    private LocalDateTime endTime;

    private Integer capacity;

    @Column(name = "current_rsrv_count")
    private int currentRsrvCount;

    @Column(name = "requires_fee")
    private boolean requiresFee;

    @Column(name = "fee_amount")
    private BigDecimal feeAmount;

    @Column(name = "touchnet_payment_code")
    private String touchnetPaymentCode;

    @Column(name = "is_active")
    private boolean isActive;

    @Column(name = "created_at", insertable = false, updatable = false)
    private LocalDateTime createdAt;

    @Transient private String organizerName;

    public String getOrganizerName() {
        return organizerName;
    }

    public void setOrganizerName(String organizerName) {
        this.organizerName = organizerName;
    }

    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public UUID getOrganizerId() {
        return organizerId;
    }

    public void setOrganizerId(UUID organizerId) {
        this.organizerId = organizerId;
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

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public boolean isVirtual() {
        return isVirtual;
    }

    public void setVirtual(boolean virtual) {
        isVirtual = virtual;
    }

    public String getMeetingLink() {
        return meetingLink;
    }

    public void setMeetingLink(String meetingLink) {
        this.meetingLink = meetingLink;
    }

    public LocalDateTime getStartTime() {
        return startTime;
    }

    public void setStartTime(LocalDateTime startTime) {
        this.startTime = startTime;
    }

    public LocalDateTime getEndTime() {
        return endTime;
    }

    public void setEndTime(LocalDateTime endTime) {
        this.endTime = endTime;
    }

    public Integer getCapacity() {
        return capacity;
    }

    public void setCapacity(Integer capacity) {
        this.capacity = capacity;
    }

    public int getCurrentRsrvCount() {
        return currentRsrvCount;
    }

    public void setCurrentRsrvCount(int currentRsrvCount) {
        this.currentRsrvCount = currentRsrvCount;
    }

    public boolean isRequiresFee() {
        return requiresFee;
    }

    public void setRequiresFee(boolean requiresFee) {
        this.requiresFee = requiresFee;
    }

    public BigDecimal getFeeAmount() {
        return feeAmount;
    }

    public void setFeeAmount(BigDecimal feeAmount) {
        this.feeAmount = feeAmount;
    }

    public String getTouchnetPaymentCode() {
        return touchnetPaymentCode;
    }

    public void setTouchnetPaymentCode(String touchnetPaymentCode) {
        this.touchnetPaymentCode = touchnetPaymentCode;
    }

    public boolean isActive() {
        return isActive;
    }

    public void setActive(boolean active) {
        isActive = active;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
