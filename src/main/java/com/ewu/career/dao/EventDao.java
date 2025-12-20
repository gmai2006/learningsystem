package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.entity.Event;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
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

    public Event create(Event entity) {
        return jpa.create(entity);
    }

    public Event update(Event entity) {
        return jpa.update(entity);
    }
}
