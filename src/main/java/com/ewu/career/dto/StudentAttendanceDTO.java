package com.ewu.career.dto;

/**
 * Represents a student's status for a specific event. Used in the Employer's Attendance Report
 * dashboard.
 */
public record StudentAttendanceDTO(
        String studentName,
        String paymentStatus, // PAID, PENDING, WAIVED
        boolean checkedIn) {}
