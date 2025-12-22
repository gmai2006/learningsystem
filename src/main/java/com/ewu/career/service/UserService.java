package com.ewu.career.service;

import com.ewu.career.dao.AppliedLearningExperienceDao;
import com.ewu.career.dao.AuditLogDao;
import com.ewu.career.dao.UserDao;
import com.ewu.career.entity.AuditLog;
import com.ewu.career.entity.User;
import com.ewu.career.util.HttpUtils;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.servlet.http.HttpServletRequest;
import java.util.List;
import java.util.Set;
import java.util.UUID;

@Stateless
@Named("UserService")
public class UserService {
    /** * Administrative roles allowed to perform destructive actions or manage all users. */
    private static final Set<String> ADMIN_ROLES = Set.of("STAFF", "FACULTY");

    @Inject private UserDao userDao;
    @Inject private AppliedLearningExperienceDao learningExperienceDao;
    @Inject private AuditLogDao auditLogDao;

    /** Retrieves a filtered and paginated list of users. */
    public List<User> findUsers(int limit, int offset, String search, String role) {
        return userDao.findUsers(limit, offset, search, role);
    }

    /** Gets the total count of users matching the filters for pagination metadata. */
    public long getTotalUserCount(String search, String role) {
        return userDao.countByFilters(search, role);
    }

    public User find(UUID id) {
        return userDao.find(id);
    }

    public User findByOktaId(String oktaId) {
        return userDao.findByOktaId(oktaId);
    }

    public User create(User newUser, User actor) {
        // Enforce RBAC for manual creation
        if (actor != null && !ADMIN_ROLES.contains(actor.getRole().name())) {
            throw new SecurityException("Forbidden: Only Staff/Faculty can create users manually.");
        }
        return userDao.create(newUser);
    }

    public User update(User updatedUser, User actor) {
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
    public void delete(UUID userId, User actor, HttpServletRequest request) {
        // Only Staff or Faculty can delete users
        boolean isAdmin = actor != null && ADMIN_ROLES.contains(actor.getRole().name());

        if (!isAdmin) {
            throw new SecurityException(
                    "Forbidden: Only Staff or Faculty are authorized to delete users.");
        }

        learningExperienceDao.deleteByUserId(userId);
        userDao.delete(userId);

        // 3. Log the action
        createAuditLog(
                actor,
                request,
                "USER_PURGED",
                "Removed user and " + userId + " associated experiences.",
                "USER");
    }

    private void createAuditLog(
            User actor,
            HttpServletRequest request,
            String action,
            String description,
            String type) {
        final String ipAddress = HttpUtils.getClientIP(request);
        AuditLog log =
                new AuditLog(
                        actor.getId(),
                        actor.getFirstName() + " " + actor.getLastName(),
                        action,
                        type,
                        null,
                        description,
                        ipAddress);

        auditLogDao.create(log);
    }
}
