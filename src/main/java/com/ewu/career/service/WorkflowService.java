package com.ewu.career.service;

import com.ewu.career.dao.AppliedLearningExperienceDao;
import com.ewu.career.dao.UserDao;
import com.ewu.career.dao.WorkflowDao;
import com.ewu.career.entity.AppliedLearningExperience;
import com.ewu.career.entity.User;
import com.ewu.career.entity.Workflow;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Stateless
@Named("WorkflowService")
public class WorkflowService {

    @Inject private WorkflowDao workflowDao;
    @Inject private AppliedLearningExperienceDao experienceDao;
    @Inject private UserDao userDao;

    /**
     * Retrieves experience and student details for the external landing page. Fulfills the
     * "no-login" requirement by providing context via token.
     */
    public Map<String, Object> getExperienceDetailsByToken(String token) {
        // 1. Validate the token and check expiry
        Workflow workflow = workflowDao.findByToken(token);
        if (workflow == null) {
            throw new SecurityException("Invalid or expired approval link.");
        }

        // 2. Fetch the linked experience
        AppliedLearningExperience experience = experienceDao.find(workflow.getExperienceId());
        if (experience == null) {
            throw new IllegalStateException("Associated experience record not found.");
        }

        // 3. Fetch student name for the supervisor's display
        User student = userDao.find(experience.getStudentId());

        // 4. Construct a DTO-like map for the React frontend
        Map<String, Object> details = new HashMap<>();
        details.put(
                "studentName",
                student != null
                        ? student.getFirstName() + " " + student.getLastName()
                        : "Unknown Student");
        details.put("title", experience.getTitle());
        details.put("type", experience.getType().name());
        details.put("organization", experience.getOrganizationName());
        details.put("startDate", experience.getStartDate());
        details.put("endDate", experience.getEndDate());
        details.put("workflowStatus", workflow.getStatus());

        return details;
    }

    /** Initiates a new approval workflow step with a secure token. */
    public Workflow initiateApprovalStep(
            AppliedLearningExperience experience,
            String approverEmail,
            String approverName,
            int stepOrder) {
        Workflow workflow = new Workflow();
        workflow.setExperienceId(experience.getId());
        workflow.setApproverEmail(approverEmail);
        workflow.setApproverName(approverName);
        workflow.setStepOrder(stepOrder);
        workflow.setStatus("PENDING");

        // Generate secure 32-byte token
        byte[] randomBytes = new byte[32];
        new SecureRandom().nextBytes(randomBytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(randomBytes);

        workflow.setAuthToken(token);
        workflow.setTokenExpiry(LocalDateTime.now().plusDays(14));

        return workflowDao.create(workflow);
    }

    /** Processes external approval without requiring a system login. */
    public void processExternalApproval(String token, String status, String comments) {
        Workflow workflow = workflowDao.findByToken(token);
        if (workflow == null) {
            throw new SecurityException("Invalid or expired approval token.");
        }

        workflow.setStatus(status);
        workflow.setComments(comments);
        workflow.setActionDate(LocalDateTime.now());

        workflowDao.update(workflow);
        checkAndCompleteExperience(workflow.getExperienceId());
    }

    private void checkAndCompleteExperience(UUID experienceId) {
        List<Workflow> steps = workflowDao.findByExperience(experienceId);
        boolean allApproved = steps.stream().allMatch(s -> "APPROVED".equals(s.getStatus()));

        if (allApproved) {
            AppliedLearningExperience exp = experienceDao.find(experienceId);
            exp.setStatus("APPROVED");
            experienceDao.update(exp);
        }
    }
}
