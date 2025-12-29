package com.ewu.career.dao;

import com.ewu.career.dao.core.JpaDao;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.inject.Named;
import jakarta.transaction.Transactional;
import java.util.UUID;

@ApplicationScoped
public class LoggingDao {

    @Inject
    @Named("DefaultJpaDao")
    private JpaDao jpa;

    /** Records a specific student profile access event. */
    @Transactional(Transactional.TxType.REQUIRES_NEW)
    public void logProfileView(
            UUID employerId, String employerName, UUID studentId, String context) {
        String sql =
                "INSERT INTO learningsystem.profile_access_logs "
                        + "(student_id, employer_id, access_context) "
                        + "VALUES (:sid, :eid, :ctx)";

        jpa.getEntityManager()
                .createNativeQuery(sql)
                .setParameter("sid", studentId)
                .setParameter("eid", employerId)
                .setParameter("ctx", context)
                .executeUpdate();

        // Additionally, log to the general system audit log
        logSystemAction(
                employerId,
                employerName,
                "VIEW_PROFILE",
                "STUDENT",
                studentId,
                "Viewed profile for " + context);
    }

    /** Generic system audit logger. */
    @Transactional(Transactional.TxType.REQUIRES_NEW)
    public void logSystemAction(
            UUID actorId,
            String actorName,
            String action,
            String targetType,
            UUID targetId,
            String details) {
        String sql =
                "INSERT INTO learningsystem.audit_logs "
                        + "(actor_id, actor_name, action, target_type, target_id, details) "
                        + "VALUES (:aid, :aname, :act, :ttype, :tid, :det)";

        jpa.getEntityManager()
                .createNativeQuery(sql)
                .setParameter("aid", actorId)
                .setParameter("aname", actorName)
                .setParameter("act", action)
                .setParameter("ttype", targetType)
                .setParameter("tid", targetId)
                .setParameter("det", details)
                .executeUpdate();
    }
}
