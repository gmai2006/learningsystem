package com.ewu.career.service;

import com.ewu.career.dao.VolunteerLogDao;
import com.ewu.career.entity.User;
import com.ewu.career.entity.VolunteerLog;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import java.util.List;
import java.util.UUID;

@Stateless
@Named("VolunteerLogService")
public class VolunteerLogService {

    @Inject private VolunteerLogDao logDao;

    public List<VolunteerLog> getLogsForStudent(UUID studentId) {
        return logDao.findByStudent(studentId);
    }

    /** Submits a volunteer log and initiates the site supervisor verification email. */
    public VolunteerLog logHours(User actor, VolunteerLog log) {
        if (!actor.getRole().name().equals("STUDENT")) {
            throw new SecurityException("Forbidden: Only students can log volunteer hours.");
        }

        log.setStudentId(actor.getId());
        log.setVerified(false); // Must be verified by supervisor

        VolunteerLog savedLog = logDao.create(log);

        // INTEGRATION POINT: Here we would trigger a Kafka event to send
        // the "Login-free approval email" to site_supervisor_email.

        return savedLog;
    }
}
