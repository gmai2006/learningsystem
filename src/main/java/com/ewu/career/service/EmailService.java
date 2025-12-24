package com.ewu.career.service;

import jakarta.enterprise.context.ApplicationScoped;

@ApplicationScoped
public class EmailService {

    public void sendInterviewInvitation(
            String recipientEmail, String studentName, String jobTitle, String companyName) {
        String subject = "Interview Invitation: " + jobTitle + " at " + companyName;

        String body =
                String.format(
                        "Hi %s,\n\n"
                            + "Great news! %s has reviewed your application for the %s position and"
                            + " would like to schedule an interview.\n\n"
                            + "Please check your EWU Career Portal for more details or wait for a"
                            + " follow-up from the recruiter.\n\n"
                            + "Go Eags!\n"
                            + "EWU Career Services",
                        studentName, companyName, jobTitle);

        // Logic to send email via SMTP or AWS SES goes here
        System.out.println("Email sent to: " + recipientEmail);
        System.out.println("Subject: " + subject);
    }
}
