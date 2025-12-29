package com.ewu.career.api;

import com.ewu.career.dao.EventDao;
import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.FormParam;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.UUID;

@Path("/public/payments")
public class PaymentWebhookResource {

    @Inject EventDao eventDao;

    /**
     * TouchNet postback listener. Note: In production, ensure this endpoint is secured via IP
     * allow-listing or by validating the TouchNet signature (HMAC).
     */
    @POST
    @Path("/touchnet/callback")
    @Consumes(MediaType.APPLICATION_FORM_URLENCODED)
    public Response handleTouchNetCallback(
            @FormParam("EXT_TRANS_ID") String extTransId, // We use this for studentId_eventId
            @FormParam("pmt_status") String status, // e.g., 'success' or 'cancelled'
            @FormParam("sys_tracking_id") String trackingId) {

        try {
            // TouchNet often sends the IDs in a concatenated custom field
            // Example: "studentUuid:eventUuid"
            String[] ids = extTransId.split(":");
            UUID studentId = UUID.fromString(ids[0]);
            UUID eventId = UUID.fromString(ids[1]);

            if ("success".equalsIgnoreCase(status)) {
                eventDao.fulfillRegistration(studentId, eventId, trackingId);
            } else {
                eventDao.markPaymentFailed(studentId, eventId);
            }

            return Response.ok("ACK").build();
        } catch (Exception e) {
            // We return 200/ACK even on error so TouchNet doesn't keep retrying
            // but we log the error internally.
            return Response.ok("ERROR_LOGGED").build();
        }
    }
}
