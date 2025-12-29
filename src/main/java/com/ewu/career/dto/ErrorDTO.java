package com.ewu.career.dto;

/** A standard wrapper for error messages and failure details. */
public record ErrorDTO(String error, String detail) {
    // Convenience constructor for single-string errors
    public ErrorDTO(String error) {
        this(error, null);
    }
}
