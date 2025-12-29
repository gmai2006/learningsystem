package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.dto.AttendanceReportDTO;
import com.ewu.career.dto.StudentAttendanceDTO;
import com.ewu.career.entity.AuditLog;
import com.ewu.career.entity.Event;
import com.ewu.career.entity.EventRegistration;
import com.ewu.career.entity.EventRegistrationId;
import com.ewu.career.util.HttpUtils;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.persistence.LockModeType;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.transaction.Transactional;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Stateless
@Named("EventDao")
public class EventDao {

    @Inject
    @Named("DefaultJpaDao")
    private JpaDao jpa;

    @Inject private AuditLogDao auditLogDao;

    public List<Event> getEventsByStatus(UUID organizerId, String status, boolean isStaff) {
        LocalDateTime now = LocalDateTime.now();

        // We select the Event AND the specific name fields from the User table
        // We use COALESCE to pick Company Name first, then fallback to First + Last name
        String jpql =
                "SELECT e, "
                        + "COALESCE(u.companyName, CONCAT(u.firstName, ' ', u.lastName)) "
                        + "FROM Event e JOIN User u ON e.organizerId = u.id "
                        + "WHERE e.isActive = true ";

        // Role-based filtering
        if (!isStaff) {
            jpql += "AND e.organizerId = :oid ";
        }

        // Temporal filtering
        if ("PAST".equalsIgnoreCase(status)) {
            jpql += "AND e.endTime < :now ORDER BY e.startTime DESC";
        } else {
            jpql += "AND e.endTime >= :now ORDER BY e.startTime ASC";
        }

        var query =
                jpa.getEntityManager().createQuery(jpql, Object[].class).setParameter("now", now);

        if (!isStaff) {
            query.setParameter("oid", organizerId);
        }

        List<Object[]> results = query.getResultList();

        // Map the Object array back into the Event entity with the transient name set
        return results.stream()
                .map(
                        result -> {
                            Event event = (Event) result[0];
                            String name = (String) result[1];
                            event.setOrganizerName(name);
                            return event;
                        })
                .toList();
    }

    public Event find(UUID id) {
        return jpa.find(Event.class, id);
    }

    /** Retrieves upcoming events for the student portal. */
    public List<Event> findUpcoming() {
        String query =
                "SELECT e FROM Event e WHERE e.startTime > CURRENT_TIMESTAMP ORDER BY e.startTime"
                        + " ASC";
        return jpa.selectAll(query, Event.class);
    }

    /** Filters events by type (e.g., 'Career Fair', 'Workshop'). */
    public List<Event> findByType(String type) {
        String query = "SELECT e FROM Event e WHERE e.type = :type";
        Map<String, Object> params = new HashMap<>();
        params.put("type", type);
        return jpa.selectAllWithParameters(query, Event.class, params);
    }

    @Transactional
    public void rsvpToEvent(UUID eventId, UUID studentId) throws Exception {
        // 1. Lock the event record for update to prevent race conditions
        Event event =
                jpa.getEntityManager().find(Event.class, eventId, LockModeType.PESSIMISTIC_WRITE);

        if (event == null) throw new Exception("Event not found");

        // 2. Capacity Check
        if (event.getCapacity() != null && event.getCurrentRsrvCount() >= event.getCapacity()) {
            throw new Exception("This event has reached maximum capacity.");
        }

        // 3. Create Registration
        EventRegistration reg = new EventRegistration();
        reg.setId(new EventRegistrationId(eventId, studentId));
        reg.setPaymentStatus(event.isRequiresFee() ? "PENDING" : "WAIVED");

        jpa.getEntityManager().persist(reg);

        // 4. Increment RSVP Count
        event.setCurrentRsrvCount(event.getCurrentRsrvCount() + 1);
        update(event);
    }

    @Transactional
    public void processCheckIn(
            UUID eventId, UUID studentId, UUID employerId, HttpServletRequest request)
            throws Exception {
        // 1. Verify the employer owns the event
        Event event = jpa.find(Event.class, eventId);
        if (event == null || !event.getOrganizerId().equals(employerId)) {
            throw new Exception("Unauthorized: You are not the organizer of this event.");
        }

        // 2. Find the registration record
        EventRegistrationId regId = new EventRegistrationId(eventId, studentId);
        EventRegistration registration = jpa.find(EventRegistration.class, regId);

        if (registration == null) {
            throw new Exception("Student is not registered for this event.");
        }

        // 3. Toggle Check-in
        if (registration.getCheckedIn()) {
            throw new Exception("Student is already checked in.");
        }

        registration.setCheckedIn(true);
        jpa.getEntityManager().persist(registration);

        final String ipAddress = HttpUtils.getClientIP(request);
        AuditLog log =
                new AuditLog(
                        employerId,
                        "Recruiter",
                        "CHECK_IN",
                        "STUDENT",
                        studentId,
                        "Checked into " + event.getTitle(),
                        ipAddress);

        auditLogDao.create(log);
    }

    public AttendanceReportDTO getAttendanceReport(UUID eventId) {
        // 1. Fetch Student Details & Check-in Status
        String sql =
                "SELECT u.first_name, u.last_name, r.payment_status, r.checked_in "
                        + "FROM learningsystem.event_registrations r "
                        + "JOIN learningsystem.users u ON r.user_id = u.id "
                        + "WHERE r.event_id = :eid";

        List<Object[]> results =
                jpa.getEntityManager()
                        .createNativeQuery(sql)
                        .setParameter("eid", eventId)
                        .getResultList();

        List<StudentAttendanceDTO> participants =
                results.stream()
                        .map(
                                row ->
                                        new StudentAttendanceDTO(
                                                row[0] + " " + row[1],
                                                (String) row[2],
                                                (Boolean) row[3]))
                        .toList();

        // 2. Calculate Aggregates
        long registered = participants.size();
        long checkedIn = participants.stream().filter(StudentAttendanceDTO::checkedIn).count();
        double rate = registered == 0 ? 0 : (double) checkedIn / registered * 100;

        return new AttendanceReportDTO(registered, checkedIn, rate, participants);
    }

    @Transactional
    public void fulfillRegistration(UUID studentId, UUID eventId, String trackingId) {
        String jpql =
                "SELECT r FROM EventRegistration r WHERE r.eventId = :eid AND r.userId = :uid";

        EventRegistration registration =
                jpa.getEntityManager()
                        .createQuery(jpql, EventRegistration.class)
                        .setParameter("eid", eventId)
                        .setParameter("uid", studentId)
                        .getSingleResult();

        if (registration != null) {
            registration.setPaymentStatus("PAID");
            jpa.getEntityManager().persist(registration);
        }
    }

    @Transactional
    public void markPaymentFailed(UUID studentId, UUID eventId) {
        String jpql =
                "SELECT r FROM EventRegistration r WHERE r.eventId = :eid AND r.userId = :uid";

        EventRegistration registration =
                jpa.getEntityManager()
                        .createQuery(jpql, EventRegistration.class)
                        .setParameter("eid", eventId)
                        .setParameter("uid", studentId)
                        .getSingleResult();

        if (registration != null) {
            registration.setPaymentStatus("FAILED");
            jpa.getEntityManager().persist(registration);
        }
    }

    public Event create(Event entity) {
        return jpa.create(entity);
    }

    public Event update(Event entity) {
        return jpa.update(entity);
    }
}
