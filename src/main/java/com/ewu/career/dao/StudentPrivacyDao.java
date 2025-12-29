package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import com.ewu.career.dto.PagedAccessLogs;
import com.ewu.career.dto.ProfileAccessLogDTO;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.UUID;

@ApplicationScoped
public class StudentPrivacyDao {

    @Inject
    @Named("DefaultJpaDao")
    private JpaDao jpa;

    @Transactional
    public void updatePrivacyFlag(UUID studentId, boolean isRestricted) {
        String sql =
                "UPDATE learningsystem.student_profiles SET is_ferpa_restricted = :val WHERE"
                        + " user_id = :sid";
        jpa.getEntityManager()
                .createNativeQuery(sql)
                .setParameter("val", isRestricted)
                .setParameter("sid", studentId)
                .executeUpdate();
    }

    public PagedAccessLogs getPagedAccessLogs(UUID studentId, int page, int size) {
        int offset = page * size;

        // 1. Get the data for the current page
        String sql =
                "SELECT e.company_name, l.accessed_at, l.access_context "
                        + "FROM learningsystem.profile_access_logs l "
                        + "JOIN learningsystem.employer_profiles e ON l.employer_id = e.user_id "
                        + "WHERE l.student_id = :sid "
                        + "ORDER BY l.accessed_at DESC "
                        + "LIMIT :limit OFFSET :offset";

        @SuppressWarnings("unchecked")
        List<Object[]> rows =
                jpa.getEntityManager()
                        .createNativeQuery(sql)
                        .setParameter("sid", studentId)
                        .setParameter("limit", size)
                        .setParameter("offset", offset)
                        .getResultList();

        List<ProfileAccessLogDTO> content =
                rows.stream()
                        .map(
                                row ->
                                        new ProfileAccessLogDTO(
                                                (String) row[0],
                                                ((java.sql.Timestamp) row[1]).toLocalDateTime(),
                                                (String) row[2]))
                        .toList();

        // 2. Get the total count for pagination math
        String countSql =
                "SELECT COUNT(*) FROM learningsystem.profile_access_logs WHERE student_id = :sid";
        long totalCount =
                ((Number)
                                jpa.getEntityManager()
                                        .createNativeQuery(countSql)
                                        .setParameter("sid", studentId)
                                        .getSingleResult())
                        .longValue();

        PagedAccessLogs result = new PagedAccessLogs();
        result.content = content;
        result.totalPages = (int) Math.ceil((double) totalCount / size);

        return result;
    }
}
