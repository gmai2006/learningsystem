package com.ewu.career.service;

import com.ewu.career.dao.EmployerProfileDao;
import com.ewu.career.entity.EmployerProfile;
import com.ewu.career.entity.User;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import java.util.UUID;

@Stateless
@Named("EmployerProfileService")
public class EmployerProfileService {

    @Inject private EmployerProfileDao employerDao;

    public EmployerProfile find(UUID userId) {
        return employerDao.find(userId);
    }

    /** Approves an employer account, allowing them to post jobs. */
    public EmployerProfile approveEmployer(User actor, UUID employerId) {
        if (!actor.getRole().name().equals("STAFF")) {
            throw new SecurityException("Forbidden: Only Staff can approve employer accounts.");
        }

        EmployerProfile profile = employerDao.find(employerId);
        if (profile != null) {
            profile.setApproved(true);
            return employerDao.update(profile);
        }
        return null;
    }
}
