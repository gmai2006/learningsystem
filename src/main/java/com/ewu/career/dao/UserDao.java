package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.entity.User;
import com.ewu.career.entity.UserRole;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
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

    public List<User> selectAll() {
        return jpa.selectAll("SELECT u FROM User u", User.class);
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
