package com.ewu.career.service;

import com.ewu.career.dao.UserDao;
import com.ewu.career.entity.User;
import com.ewu.career.entity.UserRole;
import jakarta.inject.Inject;
import java.util.Set;

public class IdentityService {
    /** * Administrative roles allowed to perform destructive actions or manage all users. */
    private static final Set<String> ADMIN_ROLES = Set.of("STAFF", "FACULTY");

    @Inject private UserDao userDao;

    public User resolveIdentity(String email, String oktaId, String first, String last) {
        User user = userDao.findByEmail(email);

        if (user == null) {
            // Option A: Just-in-time creation
            user = createNewUserFromOkta(email, oktaId, first, last);
        } else if (user.getOktaId() == null) {
            // Option B: Link the pre-created local account to the Okta identity
            user.setOktaId(oktaId);
            userDao.update(user);
        }

        return user;
    }

    public User createNewUserFromOkta(
            String email, String oktaId, String firstName, String lastName) {
        User newUser = new User();

        // Set Identifiers
        newUser.setEmail(email.toLowerCase());
        newUser.setOktaId(oktaId);

        // Set Profile Data from Okta Claims
        newUser.setFirstName(firstName);
        newUser.setLastName(lastName);

        // Default Role Assignment
        // You may want to parse Okta Groups here to determine if they are STAFF or STUDENT
        newUser.setRole(UserRole.STUDENT);

        // Initial Status
        newUser.setIsActive(true);

        // Persist to Database
        return userDao.create(newUser);
    }
}
