package com.ewu.career.dao;

import com.ewu.career.entity.VolunteerLog;
import jakarta.ejb.Stateless;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@Stateless
@Named("VolunteerLogDao")
public class VolunteerLogDao {

    @Inject
    @Named("DefaultJpaDao")
    private com.ewu.career.dao.core.JpaDao jpa;

    /** Fetches impact logs (hours, donations, etc.) for real-time visualization. */
    public List<VolunteerLog> findByStudent(UUID studentId) {
        String query =
                "SELECT v FROM VolunteerLog v WHERE v.studentId = :studentId ORDER BY v.dateLogged"
                        + " DESC";
        Map<String, Object> params = new HashMap<>();
        params.put("studentId", studentId);
        return jpa.selectAllWithParameters(query, VolunteerLog.class, params);
    }

    public VolunteerLog create(VolunteerLog entity) {
        return jpa.create(entity);
    }

    public VolunteerLog update(VolunteerLog entity) {
        return jpa.update(entity);
    }
}
