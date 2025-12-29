package com.ewu.career.dto;

/** A standard wrapper for success messages returned by the API. */
public record MessageDTO(String message) {
    public MessageDTO {
        if (message == null) message = "Operation successful";
    }
}
