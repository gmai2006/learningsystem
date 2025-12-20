package com.ewu.career.interceptor;

import jakarta.interceptor.InterceptorBinding;
import java.lang.annotation.*;

@Inherited
@InterceptorBinding
@Retention(RetentionPolicy.RUNTIME)
@Target({ElementType.METHOD, ElementType.TYPE})
public @interface AuditAction {
    /** Optional description of the action being audited. */
    String value() default "";
}
