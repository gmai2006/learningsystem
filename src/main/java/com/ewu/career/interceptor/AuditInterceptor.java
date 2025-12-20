package com.ewu.career.interceptor;

import com.ewu.career.api.security.AuthContext;
import com.ewu.career.dao.AuditLogDao;
import com.ewu.career.entity.AuditLog;
import jakarta.inject.Inject;
import jakarta.interceptor.AroundInvoke;
import jakarta.interceptor.Interceptor;
import jakarta.interceptor.InvocationContext;

@AuditAction
@Interceptor
public class AuditInterceptor {

    @Inject private AuditLogDao auditDao;

    @Inject private AuthContext authContext;

    @AroundInvoke
    public Object intercept(InvocationContext context) throws Exception {
        // 1. Execute the actual service method
        Object result = context.proceed();

        // 2. Post-execution: Create the audit log
        AuditLog entry = new AuditLog();

        // Extract actor details from the WildFly Security Context
        String username =
                (authContext.getActor() != null)
                        ? authContext.getActor().getFirstName()
                                + " "
                                + authContext.getActor().getLastName()
                        : "System/Anonymous";

        entry.setActorName(username);
        entry.setAction(formatActionName(context.getMethod().getName()));
        entry.setTargetType("JOB"); // Since we are in the JobPosting context

        auditDao.create(entry);

        return result;
    }

    private String formatActionName(String methodName) {
        // Converts "createJobPosting" to "Created Job Posting" for the Pulse UI
        return methodName
                .replaceAll(
                        String.format(
                                "%s|%s|%s",
                                "(?<=[A-Z])(?=[A-Z][a-z])",
                                "(?<=[^A-Z])(?=[A-Z])",
                                "(?<=[A-Za-z])(?=[^A-Za-z])"),
                        " ")
                .toUpperCase();
    }
}
