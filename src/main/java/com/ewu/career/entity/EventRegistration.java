package com.ewu.career.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "event_registrations")
public class EventRegistration {

    @EmbeddedId private EventRegistrationId id;

    @Column(name = "payment_status")
    private String paymentStatus; // PAID, PENDING, WAIVED

    @Column(name = "checked_in")
    private Boolean checkedIn = false;

    public EventRegistration() {}

    // Getters and Setters
    public EventRegistrationId getId() {
        return id;
    }

    public void setId(EventRegistrationId id) {
        this.id = id;
    }

    public String getPaymentStatus() {
        return paymentStatus;
    }

    public void setPaymentStatus(String paymentStatus) {
        this.paymentStatus = paymentStatus;
    }

    public Boolean getCheckedIn() {
        return checkedIn;
    }

    public void setCheckedIn(Boolean checkedIn) {
        this.checkedIn = checkedIn;
    }
}
