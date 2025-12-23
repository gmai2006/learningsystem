package com.ewu.career.util;

import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

public class TimeFormattingUtils {

    /** Converts a LocalDateTime into a "time ago" string. */
    public static String formatTimeAgo(LocalDateTime pastTime) {
        if (pastTime == null) return "Unknown time";

        LocalDateTime now = LocalDateTime.now();

        long seconds = ChronoUnit.SECONDS.between(pastTime, now);
        long minutes = ChronoUnit.MINUTES.between(pastTime, now);
        long hours = ChronoUnit.HOURS.between(pastTime, now);
        long days = ChronoUnit.DAYS.between(pastTime, now);

        if (seconds < 60) {
            return "Just now";
        } else if (minutes < 60) {
            return minutes + (minutes == 1 ? " minute ago" : " minutes ago");
        } else if (hours < 24) {
            return hours + (hours == 1 ? " hour ago" : " hours ago");
        } else if (days < 7) {
            return days + (days == 1 ? " day ago" : " days ago");
        } else if (days < 30) {
            long weeks = days / 7;
            return weeks + (weeks == 1 ? " week ago" : " weeks ago");
        } else {
            // Default to a simple date format if it's over a month old
            return pastTime.getMonthValue()
                    + "/"
                    + pastTime.getDayOfMonth()
                    + "/"
                    + pastTime.getYear();
        }
    }
}
