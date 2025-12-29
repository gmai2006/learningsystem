package com.ewu.career.api.provider;

import com.ewu.career.dto.ErrorDTO;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.ExceptionMapper;
import jakarta.ws.rs.ext.Provider;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Catches all unhandled exceptions and returns a consistent ErrorDTO. This prevents leaking
 * internal stack traces to the frontend.
 */
@Provider
public class GlobalExceptionMapper implements ExceptionMapper<Throwable> {

    private static final Logger LOG = LoggerFactory.getLogger(GlobalExceptionMapper.class);

    @Override
    public Response toResponse(Throwable exception) {
        // 1. Log the full stack trace for internal debugging
        LOG.error("Unhandled Exception caught by GlobalMapper: ", exception);

        // 2. Handle JAX-RS built-in exceptions (like 404 Not Found or 405 Method Not Allowed)
        if (exception instanceof WebApplicationException webAppEx) {
            return Response.fromResponse(webAppEx.getResponse())
                    .entity(new ErrorDTO("Request Error", webAppEx.getMessage()))
                    .type(MediaType.APPLICATION_JSON)
                    .build();
        }

        // 3. Handle Business/Database Exceptions (Default to 400 Bad Request)
        // You can add 'else if' blocks here for specific types like PersistenceException
        String errorMessage =
                exception.getMessage() != null
                        ? exception.getMessage()
                        : "An unexpected internal error occurred.";

        return Response.status(Response.Status.BAD_REQUEST)
                .entity(new ErrorDTO("Operation Failed", errorMessage))
                .type(MediaType.APPLICATION_JSON)
                .build();
    }
}
