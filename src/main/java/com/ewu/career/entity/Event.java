package com.ewu.career.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.UUID;

/**
 * Entity representing Career Fairs, Workshops, and Information Sessions. Supports fee management
 * via TouchNet integration.
 */
@Entity
@Table(name = "events", schema = "learningsystem")
public class Event {

    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private UUID id;

    /** The organizer of the event, typically a Staff member or an Employer. */
    @Column(name = "organizer_id")
    private UUID organizerId;

    @Column(nullable = false)
    private String title;

    /** Event type (e.g., 'Career Fair', 'Workshop', 'Info Session'). */
    private String type;

    private String location;

    @Column(name = "start_time")
    private LocalDateTime startTime;

    @Column(name = "end_time")
    private LocalDateTime endTime;

    /** Flag to determine if registration requires a fee. */
    @Column(name = "requires_fee")
    private boolean requiresFee;

    /** The cost of the event, if applicable. */
    @Column(name = "fee_amount", precision = 10, scale = 2)
    private BigDecimal feeAmount;

    /** Reference code for processing payments through the TouchNet gateway. */
    @Column(name = "touchnet_payment_code")
    private String touchnetPaymentCode;

    // Default Constructor
    public Event() {}

    // Getters and Setters
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
}
