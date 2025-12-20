package com.ewu.career.api.security;

import com.ewu.career.dao.UserDao;
import com.ewu.career.entity.User;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import jakarta.annotation.Priority;
import jakarta.inject.Inject;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerRequestFilter;
import jakarta.ws.rs.core.Response;
import jakarta.ws.rs.ext.Provider;
import java.io.IOException;
import java.text.ParseException;

@Provider
@Priority(Priorities.AUTHENTICATION)
public class JwtAuthFilter implements ContainerRequestFilter {
    public static final String AUTH_USER_PROP = "com.ewu.career.api.security.user";
    @Inject private UserDao userDao;

    @Inject private AuthContext authContext;

    @Override
    public void filter(ContainerRequestContext requestContext) throws IOException {
        System.out.println("JwtAuthFilter is running...");
        String authHeader = requestContext.getHeaderString("Authorization");

        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            // No token: let resources decide (actor == null -> 401 in your methods)
            return;
        }

        String rawToken = authHeader.substring("Bearer ".length()).trim();

        try {
            final SignedJWT jwt = SignedJWT.parse(rawToken);
            final JWTClaimsSet claimsSet = jwt.getJWTClaimsSet();
            // Prefer email; fallback to preferred_username or sub
            String email = claimsSet.getClaimAsString("email");
            if (email == null) {
                email = claimsSet.getStringClaim("preferred_username");
            }
            if (email == null) {
                // last resort, you could use sub
                email = claimsSet.getSubject();
            }

            if (email == null) {
                abort(requestContext, Response.Status.UNAUTHORIZED, "Token does not contain email");
                return;
            }

            User user = userDao.findByEmail(email);
            if (user == null) {
                abort(requestContext, Response.Status.UNAUTHORIZED, "No matching user found");
                return;
            }
            authContext.setActor(user);

        } catch (ParseException e) {
            abort(requestContext, Response.Status.UNAUTHORIZED, "Invalid token: " + e.getMessage());
        }
    }

    private void abort(ContainerRequestContext ctx, Response.Status status, String msg) {
        ctx.abortWith(Response.status(status).entity(msg).build());
    }
}
