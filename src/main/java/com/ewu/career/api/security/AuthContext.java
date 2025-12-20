package com.ewu.career.api.security;

import com.ewu.career.entity.User;
import jakarta.enterprise.context.RequestScoped;
import jakarta.enterprise.inject.Produces;

/** Holds the authenticated user for the duration of the HTTP request. */
@RequestScoped
public class AuthContext {

    private User actor;

    public User getActor() {
        if (actor == null) {
            System.err.println("CRITICAL: Producer called but no User found in");
            throw new IllegalStateException("User not authenticated");
        }
        return actor;
    }

    public void setActor(User actor) {
        this.actor = actor;
    }

    @Produces
    @RequestScoped
    public User produceUser() {
        // This method is now in the same bean the filter uses
        System.out.println(
                "Producing user from AuthContext: " + (actor != null ? actor.getEmail() : "null"));
        return this.actor;
    }
}
