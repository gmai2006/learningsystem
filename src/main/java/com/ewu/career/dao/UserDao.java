package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.entity.User;
import com.ewu.career.entity.UserRole;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.persistence.TypedQuery;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/** DAO for managing EWU Users. Supports SSO (Okta) and Banner integration lookups. */
@Stateless
@Named("UserDao")
public class UserDao {

    @Inject
    @Named("DefaultJpaDao")
    private JpaDao jpa;

    public User find(UUID id) {
        return jpa.find(User.class, id);
    }

    /**
     * Retrieves a user by their Okta Subject ID. Essential for mapping Okta claims to local user
     * records.
     */
    public User findByOktaId(String oktaId) {
        String query = "SELECT u FROM User u WHERE u.oktaId = :oktaId";
        Map<String, Object> params = new HashMap<>();
        params.put("oktaId", oktaId);
        List<User> list = jpa.selectAllWithParameters(query, User.class, params);
        return list.isEmpty() ? null : list.get(0);
    }

    /**
     * Retrieves a user by their EWU Banner ID. Used by the Kafka consumer to process student
     * demographic updates.
     */
    public User findByBannerId(String bannerId) {
        String query = "SELECT u FROM User u WHERE u.bannerId = :bannerId";
        Map<String, Object> params = new HashMap<>();
        params.put("bannerId", bannerId);
        List<User> list = jpa.selectAllWithParameters(query, User.class, params);
        return list.isEmpty() ? null : list.get(0);
    }

    public User findByEmail(String email) {
        String query = "SELECT u FROM User u WHERE u.email = :email";
        Map<String, Object> params = new HashMap<>();
        params.put("email", email);
        List<User> list = jpa.selectAllWithParameters(query, User.class, params);
        return list.isEmpty() ? null : list.getFirst();
    }

    /**
     * Counts users based on their assigned role. Used for the "Total Active Students" and "Employer
     * Partners" KPIs.
     */
    public long countByRole(String roleName) {
        return jpa.getEntityManager()
                .createQuery("SELECT COUNT(u) FROM User u WHERE u.role = :role", Long.class)
                .setParameter("role", UserRole.valueOf(roleName))
                .getSingleResult();
    }

    /** Finds users based on partial name or email matching and role filtering. */
    public List<User> findUsers(int limit, int offset, String search, String role) {
        StringBuilder jpql = new StringBuilder("SELECT u FROM User u WHERE 1=1 ");

        appendFilters(jpql, search, role);
        jpql.append("ORDER BY u.lastName ASC, u.firstName ASC");

        TypedQuery<User> query =
                jpa.getEntityManager()
                        .createQuery(jpql.toString(), User.class)
                        .setFirstResult(offset)
                        .setMaxResults(limit);

        bindParameters(query, search, role);
        return query.getResultList();
    }

    /** Counts the total number of users matching the filter criteria. */
    public long countByFilters(String search, String role) {
        StringBuilder jpql = new StringBuilder("SELECT COUNT(u) FROM User u WHERE 1=1 ");

        appendFilters(jpql, search, role);

        TypedQuery<Long> query = jpa.getEntityManager().createQuery(jpql.toString(), Long.class);
        bindParameters(query, search, role);

        return query.getSingleResult();
    }

    /** Counts users of a specific role created on or after the provided timestamp. */
    public long countUsersByRoleAndDate(UserRole role, LocalDateTime since) {
        String jpql = "SELECT COUNT(u) FROM User u WHERE u.role = :role AND u.createdAt >= :since";

        return jpa.getEntityManager()
                .createQuery(jpql, Long.class)
                .setParameter("role", role)
                .setParameter("since", since)
                .getSingleResult();
    }

    /** Shared logic to build the WHERE clause for search and role. */
    private void appendFilters(StringBuilder jpql, String search, String role) {
        if (search != null && !search.isEmpty()) {
            jpql.append("AND (LOWER(u.email) LIKE LOWER(:query) ")
                    .append("OR LOWER(u.firstName) LIKE LOWER(:query) ")
                    .append("OR LOWER(u.lastName) LIKE LOWER(:query) ")
                    .append("OR LOWER(CONCAT(u.firstName, ' ', u.lastName)) LIKE LOWER(:query)) ");
        }

        if (role != null && !role.isEmpty()) {
            // Correct JPQL: Compare the field to a parameter.
            // JPA handles the conversion from the Enum object to the DB Type.
            jpql.append("AND u.role = :role ");
        }
    }

    private void bindParameters(TypedQuery<?> query, String search, String role) {
        if (search != null && !search.isEmpty()) {
            query.setParameter("query", "%" + search + "%");
        }

        if (role != null && !role.isEmpty()) {
            try {
                // CRITICAL: Convert the string "STUDENT" into the UserRole ENUM object
                UserRole roleEnum = UserRole.valueOf(role.toUpperCase());
                query.setParameter("role", roleEnum);
            } catch (IllegalArgumentException e) {
                // If the role string is invalid, bind a null or a dummy value
                // so the query doesn't crash but also doesn't match anything.
                query.setParameter("role", null);
            }
        }
    }

    public User create(User entity) {
        return jpa.create(entity);
    }

    public User update(User entity) {
        return jpa.update(entity);
    }

    public void delete(UUID id) {
        jpa.delete(User.class, id);
    }
}
