package com.ewu.career.service;

import com.ewu.career.dao.StudentProfileDao;
import com.ewu.career.dao.UserDao;
import com.ewu.career.entity.StudentProfile;
import com.ewu.career.entity.User;
import com.ewu.career.entity.UserRole;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.ejb.ActivationConfigProperty;
import jakarta.ejb.MessageDriven;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.jms.Message;
import javax.jms.MessageListener;
import org.apache.kafka.clients.consumer.ConsumerRecord;

@MessageDriven(
        activationConfig = {
            @ActivationConfigProperty(
                    propertyName = "topic",
                    propertyValue = "banner.student.updates"),
            @ActivationConfigProperty(
                    propertyName = "groupId",
                    propertyValue = "career-services-group"),
            @ActivationConfigProperty(
                    propertyName = "bootstrap.servers",
                    propertyValue = "kafka-service:9092")
        })
public class BannerSyncConsumer implements MessageListener {

    private static final Logger LOGGER = Logger.getLogger(BannerSyncConsumer.class.getName());
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Inject private UserDao userDao;

    @Inject private StudentProfileDao studentProfileDao;

    @Override
    public void onMessage(Message message) {
        // Your logic here
    }

    @Transactional
    public void onMessage(ConsumerRecord<String, String> record) {
        try {
            JsonNode payload = objectMapper.readTree(record.value());
            String bannerId = payload.get("banner_id").asText();

            // 1. Manage the Core User record
            User user = userDao.findByBannerId(bannerId);
            if (user == null) {
                user = new User();
                user.setBannerId(bannerId);
                user.setRole(UserRole.STUDENT);
                user.setIsActive(true);
                user = userDao.create(user); // Persistence generates the UUID
            }

            // Update common demographic fields
            user.setEmail(payload.get("email").asText());
            user.setFirstName(payload.get("first_name").asText());
            user.setLastName(payload.get("last_name").asText());
            userDao.update(user);

            // 2. Manage the Student Profile record (The "Second Table")
            StudentProfile profile = studentProfileDao.find(user.getId());
            if (profile == null) {
                profile = new StudentProfile();
                profile.setUserId(user.getId()); // Links via FK to users.id
            }

            // Update eligibility and academic data from Banner
            profile.setIsWorkStudyEligible(payload.get("fws_eligible").asBoolean());
            profile.setMajor(payload.get("major").asText());
            if (payload.has("gpa") && !payload.get("gpa").isNull()) {
                // Using string constructor to avoid double-precision artifacts
                profile.setGpa(new java.math.BigDecimal(payload.get("gpa").asText()));
            }

            if (studentProfileDao.find(user.getId()) == null) {
                studentProfileDao.create(profile);
            } else {
                studentProfileDao.update(profile);
            }

            LOGGER.log(Level.INFO, "Banner Sync: Updated user and profile for {0}", bannerId);

        } catch (Exception e) {
            LOGGER.log(Level.SEVERE, "Failed to sync Banner data: " + record.value(), e);
        }
    }
}
