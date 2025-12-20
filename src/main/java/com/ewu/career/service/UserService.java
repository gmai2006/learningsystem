package com.ewu.career.service;

import com.ewu.career.dao.UserDao;
import com.ewu.career.entity.User;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Stateless
@Named("UserService")
public class UserService {
    /** * Administrative roles allowed to perform destructive actions or manage all users. */
    private static final Set<String> ADMIN_ROLES = Set.of("STAFF", "FACULTY");

    @Inject private UserDao userDao;

    public User find(UUID id) {
        return userDao.find(id);
    }

    public List<User> findAll() {
        return userDao.selectAll();
    }

    public User findByOktaId(String oktaId) {
        return userDao.findByOktaId(oktaId);
    }

    public User create(User actor, User newUser) {
        // Enforce RBAC for manual creation
        if (actor != null && !ADMIN_ROLES.contains(actor.getRole().name())) {
            throw new SecurityException("Forbidden: Only Staff/Faculty can create users manually.");
        }
        return userDao.create(newUser);
    }

    public User update(User actor, User updatedUser) {
        // Allow users to update themselves, or admins to update anyone
        boolean isSelf = actor != null && actor.getId().equals(updatedUser.getId());
        boolean isAdmin = actor != null && ADMIN_ROLES.contains(actor.getRole().name());

        if (!isSelf && !isAdmin) {
            throw new SecurityException("Forbidden: Cannot update another user's profile.");
        }
        return userDao.update(updatedUser);
    }

    /**
     * Deletes a user record by ID. Restricted strictly to administrative roles to maintain system
     * integrity. * @param actor The user performing the action.
     *
     * @param userId The ID of the user to be deleted.
     */
    public void delete(User actor, UUID userId) {
        // Only Staff or Faculty can delete users
        boolean isAdmin = actor != null && ADMIN_ROLES.contains(actor.getRole().name());

        if (!isAdmin) {
            throw new SecurityException(
                    "Forbidden: Only Staff or Faculty are authorized to delete users.");
        }

        userDao.delete(userId);
    }
}
