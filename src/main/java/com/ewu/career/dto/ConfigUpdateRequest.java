package com.ewu.career.dto;

import java.util.Map;

public class ConfigUpdateRequest {
    private Map<String, String> settings;

    public Map<String, String> getSettings() {
        return settings;
    }

    public void setSettings(Map<String, String> settings) {
        this.settings = settings;
    }
}
