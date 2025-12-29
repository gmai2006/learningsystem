package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.dto.StudentProjectDTO;
import com.ewu.career.entity.VolunteerLog;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class VolunteerDao {

    @Inject
    @Named("DefaultJpaDao")
    private JpaDao jpa;

    /**
     * Retrieves volunteer projects for a student. Joins JobApplication -> JobPosting ->
     * EmployerProfile.
     */
    public List<StudentProjectDTO> getStudentActiveProjects(UUID studentId) {
        // We use the JobPosting entity (j) and join it with EmployerProfile (ep)
        // to access the companyName field.
        String jpql =
                "SELECT new com.ewu.career.dto.StudentProjectDTO("
                        + "a.id, "
                        + // JobApplication ID
                        "j.title, "
                        + // JobPosting Title
                        "ep.companyName, "
                        + // From EmployerProfile table
                        "a.status, "
                        + // From JobApplication table
                        "(SELECT COALESCE(SUM(vl.hoursWorked), 0) "
                        + " FROM VolunteerLog vl "
                        + " WHERE vl.experienceId = j.id "
                        + " AND vl.studentId = :sid "
                        + " AND vl.status = 'APPROVED')) "
                        + "FROM JobApplication a "
                        + "JOIN JobPosting j ON a.jobId = j.id "
                        + "JOIN EmployerProfile ep ON j.employerId = ep.userId "
                        + // Joining EmployerProfile
                        "WHERE a.studentId = :sid "
                        + "AND j.category = 'VOLUNTEER' "
                        + "ORDER BY a.createdAt DESC";

        return jpa.getEntityManager()
                .createQuery(jpql, StudentProjectDTO.class)
                .setParameter("sid", studentId)
                .getResultList();
    }

    public VolunteerLog create(VolunteerLog entity) {
        return jpa.create(entity);
    }
}
