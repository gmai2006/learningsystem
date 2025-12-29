package com.ewu.career.dto;

public record AttendanceReportDTO(
        long totalRegistered,
        long totalCheckedIn,
        double attendanceRate,
        java.util.List<StudentAttendanceDTO> participants) {}
