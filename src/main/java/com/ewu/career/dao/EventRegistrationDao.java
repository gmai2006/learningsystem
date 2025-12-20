package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.entity.EventRegistration;
import com.ewu.career.entity.EventRegistrationId;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Stateless
@Named("EventRegistrationDao")
public class EventRegistrationDao {

    @Inject
    @Named("DefaultJpaDao")
    private JpaDao jpa;

    /** Finds a registration by the composite key (eventId, userId). */
    public EventRegistration find(UUID eventId, UUID userId) {
        EventRegistrationId id = new EventRegistrationId(eventId, userId);
        return jpa.find(EventRegistration.class, id);
    }

    /** Retrieves all students registered for a specific event (e.g., for check-in lists). */
    public List<EventRegistration> findByEvent(UUID eventId) {
        String query = "SELECT r FROM EventRegistration r WHERE r.id.eventId = :eventId";
        Map<String, Object> params = new HashMap<>();
        params.put("eventId", eventId);
        return jpa.selectAllWithParameters(query, EventRegistration.class, params);
    }

    /** Retrieves all events a student is registered for. */
    public List<EventRegistration> findByUser(UUID userId) {
        String query = "SELECT r FROM EventRegistration r WHERE r.id.userId = :userId";
        Map<String, Object> params = new HashMap<>();
        params.put("userId", userId);
        return jpa.selectAllWithParameters(query, EventRegistration.class, params);
    }

    public EventRegistration create(EventRegistration entity) {
        return jpa.create(entity);
    }

    public EventRegistration update(EventRegistration entity) {
        return jpa.update(entity);
    }
}
