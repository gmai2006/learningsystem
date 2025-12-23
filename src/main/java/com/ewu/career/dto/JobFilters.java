package com.ewu.career.dto;

import jakarta.ws.rs.QueryParam;

/** Simple container for job search and filtering parameters. */
public class JobFilters {

    @QueryParam("search")
    private String search;

    @QueryParam("fundingSource")
    private String fundingSource;

    @QueryParam("onCampus")
    private Boolean onCampus;

    // Getters and Setters
    public String getSearch() {
        return search;
    }

    public void setSearch(String search) {
        this.search = search;
    }

    public String getFundingSource() {
        return fundingSource;
    }

    public void setFundingSource(String fundingSource) {
        this.fundingSource = fundingSource;
    }

    public Boolean getOnCampus() {
        return onCampus;
    }

    public void setOnCampus(Boolean onCampus) {
        this.onCampus = onCampus;
    }

    /** Helper to check if any filters are active. */
    public boolean hasFilters() {
        return (search != null && !search.isEmpty())
                || (fundingSource != null && !fundingSource.isEmpty())
                || onCampus != null;
    }
}
