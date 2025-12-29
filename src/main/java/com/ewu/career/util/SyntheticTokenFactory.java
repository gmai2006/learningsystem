package com.ewu.career.util;

import com.nimbusds.jose.*;
import com.nimbusds.jose.crypto.MACSigner;
import com.nimbusds.jwt.JWTClaimsSet;
import com.nimbusds.jwt.SignedJWT;
import java.nio.charset.StandardCharsets;
import java.util.Date;

public class SyntheticTokenFactory {

    private static final byte[] SECRET =
            "local-dev-secret-at-least-32-bytes!".getBytes(StandardCharsets.UTF_8);

    public static void main(String[] args) {
        try {
            System.out.println(createDevToken("recruiting@spokanetech.com", "EMPLOYER"));
            System.out.println(createDevToken("aeagle@ewu.edu", "STUDENT"));
            System.out.println(createDevToken("test@datascience9.com", "STAFF"));
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    public static String createDevToken(String email, String subject) throws Exception {

        JWTClaimsSet claims =
                new JWTClaimsSet.Builder()
                        .issuer("https://auth.local/learningsystem")
                        .audience("learningsystem")
                        .subject(subject)
                        .claim("email", email)
                        .expirationTime(new Date(System.currentTimeMillis() + 3600_000))
                        .issueTime(new Date())
                        .build();

        SignedJWT jwt = new SignedJWT(new JWSHeader(JWSAlgorithm.HS256), claims);

        jwt.sign(new MACSigner(SECRET));

        return jwt.serialize();
    }
}
