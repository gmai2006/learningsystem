package com.ewu.career.dto;

/**
 * Specialized DTO for fetching student and job metadata required to fire automated email
 * notifications.
 */
public record ApplicantNotificationDetails(
        String studentEmail, String studentName, String jobTitle, String companyName) {}
