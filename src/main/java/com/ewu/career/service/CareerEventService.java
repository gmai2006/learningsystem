package com.ewu.career.service;

import com.ewu.career.dao.EventDao;
import com.ewu.career.entity.Event;
import com.ewu.career.entity.User;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import java.util.Set;

@Stateless
@Named("CareerEventService")
public class CareerEventService {
    private static final Set<String> ORGANIZER_ROLES = Set.of("STAFF", "EMPLOYER");

    @Inject private EventDao eventDao;

    public Event createEvent(User actor, Event event) {
        if (!ORGANIZER_ROLES.contains(actor.getRole().name())) {
            throw new SecurityException("Forbidden: Only Staff or Employers can organize events");
        }
        return eventDao.create(event);
    }

    public Event updateEvent(User actor, Event event) {
        boolean isOrganizer = actor.getId().equals(event.getOrganizerId());
        boolean isStaff = actor.getRole().name().equals("STAFF");

        if (!isOrganizer && !isStaff) {
            throw new SecurityException("Forbidden: Not authorized to modify this event");
        }
        return eventDao.update(event);
    }
}
