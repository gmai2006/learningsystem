package com.ewu.career.api;

import com.ewu.career.dao.AuditLogDao;
import com.ewu.career.entity.*;
import com.ewu.career.service.AppliedLearningService;
import com.ewu.career.service.UserService;
import com.ewu.career.service.WorkflowService;
import com.ewu.career.util.HttpUtils;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.client.j2se.MatrixToImageWriter;
import com.google.zxing.common.BitMatrix;
import com.google.zxing.qrcode.QRCodeWriter;
import com.lowagie.text.*;
import com.lowagie.text.Font;
import com.lowagie.text.Image;
import com.lowagie.text.pdf.PdfWriter;
import jakarta.inject.Inject;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.*;
import jakarta.ws.rs.core.*;
import java.awt.*;
import java.io.ByteArrayOutputStream;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * REST API for managing Applied Learning Experiences. Handles the 16 types and coordinates workflow
 * initiation.
 */
@Path("/admin/applied-learning")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class AppliedLearningResource {

    @Inject private AppliedLearningService learningService;

    @Inject private WorkflowService workflowService;

    @Inject private AuditLogDao auditLogDao;

    @Inject private UserService userService;

    /** Inject the current authenticated user. */
    @Inject User actor;

    /** Marks an experience as verified and sets the timestamp. */
    @PUT
    @Path("/{id}/verify")
    public Response verifyExperience(
            @Context HttpServletRequest request, @PathParam("id") UUID id) {
        if (actor == null) {
            return Response.status(Response.Status.UNAUTHORIZED)
                    .entity("Authentication required.")
                    .build();
        }

        if (actor.getRole() != UserRole.STAFF) {
            return Response.status(Response.Status.FORBIDDEN)
                    .entity("Only Staff can access the Recruitment Silo.")
                    .build();
        }

        // 2. Retrieve the Experience
        AppliedLearningExperience exp = learningService.find(id);
        if (exp == null) {
            return Response.status(Response.Status.NOT_FOUND)
                    .entity("Experience record not found.")
                    .build();
        }

        // 3. Update Verification State
        exp.setVerified(true);
        exp.setVerifiedAt(LocalDateTime.now());

        // Ensure status reflects the verification (moving from PENDING to APPROVED)
        if ("PENDING".equals(exp.getStatus())) {
            exp.setStatus("APPROVED");
        }

        learningService.update(actor, exp);

        // 4. Audit Log: Critical for university compliance
        createAuditLog(
                actor,
                request,
                "EXPERIENCE_VERIFIED",
                "Approve learning experience for ID: " + id,
                exp);

        return Response.ok(exp).build();
    }

    /** Retrieves all experiences for a specific student. Used by the Student Portal Dashboard. */
    @GET
    @Path("/student/{studentId}")
    public Response getStudentExperiences(@PathParam("studentId") UUID studentId) {
        List<AppliedLearningExperience> experiences = learningService.findByStudent(studentId);
        return Response.ok(experiences).build();
    }

    @GET
    public Response findExperiences() {
        if (actor.getRole() != UserRole.STAFF) {
            return Response.status(Response.Status.FORBIDDEN).build();
        }
        List<AppliedLearningExperience> results = learningService.searchByMetadata(new HashMap<>());
        return Response.ok(results).build();
    }

    @GET
    @Path("/filter")
    public Response findExperiences(@Context UriInfo uriInfo) {
        if (actor.getRole() != UserRole.STAFF) {
            return Response.status(Response.Status.FORBIDDEN).build();
        }

        // Convert UriInfo parameters to a Map
        MultivaluedMap<String, String> queryParams = uriInfo.getQueryParameters();
        Map<String, String> filters = new HashMap<>();

        // Extract all parameters that aren't standard pagination/sort keys
        queryParams.forEach(
                (key, values) -> {
                    if (!key.equals("limit") && !key.equals("offset")) {
                        filters.put(key, values.getFirst());
                    }
                });

        List<AppliedLearningExperience> results = learningService.searchByMetadata(filters);
        return Response.ok(results).build();
    }

    /**
     * Submits a new experience and initiates the first approval step. Maps the React form data to
     * the Postgres JSONB structure.
     */
    @POST
    @Path("/create")
    public Response createExperience(Map<String, Object> payload) {

        AppliedLearningExperience experience = new AppliedLearningExperience();
        experience.setStudentId(UUID.fromString((String) payload.get("studentId")));
        experience.setTitle((String) payload.get("title"));
        experience.setType(LearningType.valueOf((String) payload.get("type")));
        experience.setOrganizationName((String) payload.get("organizationName"));

        // Handle dynamic metadata for the 16 types
        if (payload.containsKey("typeSpecificData")) {
            experience.setTypeSpecificData((Map<String, Object>) payload.get("typeSpecificData"));
        }

        // 1. Save the Experience
        AppliedLearningExperience savedExp = learningService.create(null, experience);

        // 2. Initiate the first "No-Login" Workflow step
        String approverEmail = (String) payload.get("approverEmail");
        String approverName = (String) payload.get("approverName");

        if (approverEmail != null) {
            workflowService.initiateApprovalStep(savedExp, approverEmail, approverName, 1);
        }

        return Response.status(Response.Status.CREATED).entity(savedExp).build();
    }

    /** Filters experiences by type for administrative reporting. */
    @GET
    @Path("/type")
    public Response getByType(@QueryParam("type") LearningType type) {
        return Response.ok(learningService.findByType(type)).build();
    }

    @GET
    @Path("/{id}/pdf")
    @Produces("application/pdf")
    public Response downloadExperiencePdf(@PathParam("id") UUID id) {
        AppliedLearningExperience exp = learningService.find(id);
        User student = userService.find(exp.getStudentId());

        ByteArrayOutputStream out = new ByteArrayOutputStream();
        Document document = new Document(PageSize.A4);

        try {
            PdfWriter.getInstance(document, out);
            document.open();

            // 1. Header: EWU Branding
            Font titleFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 18, Color.BLACK);
            Paragraph header =
                    new Paragraph(
                            "EASTERN WASHINGTON UNIVERSITY\nCareer Services Verification",
                            titleFont);
            header.setAlignment(Element.ALIGN_CENTER);
            document.add(header);
            document.add(new Paragraph(" ")); // Spacer

            // 2. Student & Experience Core Info
            document.add(
                    new Paragraph(
                            "Student Name: "
                                    + student.getFirstName()
                                    + " "
                                    + student.getLastName()));
            document.add(new Paragraph("Experience Type: " + exp.getType()));
            document.add(new Paragraph("Organization: " + exp.getOrganizationName()));
            document.add(new Paragraph("Status: " + exp.getStatus()));
            document.add(new Paragraph(" "));

            // 3. Dynamic Metadata (JSONB)
            Font metaHeaderFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 12);
            document.add(new Paragraph("VERIFIED DETAILS:", metaHeaderFont));
            exp.getTypeSpecificData()
                    .forEach(
                            (key, value) -> {
                                document.add(
                                        new Paragraph("• " + key.replace("_", " ") + ": " + value));
                            });
            document.add(new Paragraph(" "));

            // 4. Digital Signature & QR Code
            // URL for external verification (e.g., public lookup page)
            String verifyUrl = "https://career-silo.ewu.edu/verify/" + id;
            com.lowagie.text.Image qrCodeImage = generateQrCode(verifyUrl);
            qrCodeImage.setAlignment(Element.ALIGN_RIGHT);
            qrCodeImage.scaleAbsolute(100, 100);
            document.add(qrCodeImage);

            document.add(new Paragraph("Verification Date: " + exp.getVerifiedAt()));
            document.add(new Paragraph("Digital Signature ID: " + id.toString().substring(0, 8)));

            document.close();
        } catch (Exception e) {
            return Response.serverError().build();
        }

        return Response.ok(out.toByteArray())
                .header("Content-Disposition", "attachment; filename=\"EWU_Verify_" + id + ".pdf\"")
                .build();
    }

    private Image generateQrCode(String text) throws Exception {
        QRCodeWriter qrCodeWriter = new QRCodeWriter();
        BitMatrix bitMatrix = qrCodeWriter.encode(text, BarcodeFormat.QR_CODE, 200, 200);

        ByteArrayOutputStream pngStream = new ByteArrayOutputStream();
        MatrixToImageWriter.writeToStream(bitMatrix, "PNG", pngStream);
        return Image.getInstance(pngStream.toByteArray());
    }

    private void createAuditLog(
            User actor,
            HttpServletRequest request,
            String action,
            String description,
            AppliedLearningExperience exp) {
        final String ipAddress = HttpUtils.getClientIP(request);
        AuditLog log =
                new AuditLog(
                        actor.getId(),
                        actor.getFirstName() + " " + actor.getLastName(),
                        action,
                        exp.getType().name(),
                        null,
                        description,
                        ipAddress);

        auditLogDao.create(log);
    }
}
