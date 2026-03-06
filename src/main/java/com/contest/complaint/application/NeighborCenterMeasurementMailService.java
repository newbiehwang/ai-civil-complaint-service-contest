package com.contest.complaint.application;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;

@Service
public class NeighborCenterMeasurementMailService {

    private static final Logger log = LoggerFactory.getLogger(NeighborCenterMeasurementMailService.class);
    private static final ZoneId KST = ZoneId.of("Asia/Seoul");
    private static final DateTimeFormatter SENT_AT_FORMATTER =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss (z)", Locale.KOREAN).withZone(KST);

    private final JavaMailSender javaMailSender;
    private final boolean mailEnabled;
    private final String recipientEmail;
    private final String subjectTemplate;
    private final String fromAddress;

    public NeighborCenterMeasurementMailService(
            ObjectProvider<JavaMailSender> javaMailSenderProvider,
            @Value("${complaint.neighbor-center.measurement-mail-enabled:false}") boolean mailEnabled,
            @Value("${complaint.neighbor-center.measurement-recipient-email:}") String recipientEmail,
            @Value("${complaint.neighbor-center.measurement-mail-subject:[정부24 데모] 층간소음 측정 신청서 제출}") String subjectTemplate,
            @Value("${complaint.neighbor-center.measurement-mail-from:}") String fromAddress
    ) {
        this.javaMailSender = javaMailSenderProvider.getIfAvailable();
        this.mailEnabled = mailEnabled;
        this.recipientEmail = recipientEmail == null ? "" : recipientEmail.trim();
        this.subjectTemplate = subjectTemplate == null ? "" : subjectTemplate.trim();
        this.fromAddress = fromAddress == null ? "" : fromAddress.trim();
    }

    public MailSendResult sendMeasurementDocument(
            UUID caseId,
            Map<String, Object> filledSlots,
            NeighborCenterMeasurementDocumentService.GeneratedMeasurementDocument generatedDocument
    ) {
        return sendMeasurementDocument(caseId, filledSlots, generatedDocument, null, null);
    }

    public MailSendResult sendMeasurementDocument(
            UUID caseId,
            Map<String, Object> filledSlots,
            NeighborCenterMeasurementDocumentService.GeneratedMeasurementDocument generatedDocument,
            String recipientOverride,
            String replyTo
    ) {
        Objects.requireNonNull(caseId, "caseId");
        Objects.requireNonNull(generatedDocument, "generatedDocument");

        if (!mailEnabled) {
            log.info("neighbor-center mail skipped because disabled caseId={}", caseId);
            return MailSendResult.disabled();
        }
        if (javaMailSender == null) {
            throw new IllegalStateException("JavaMailSender is not configured. Set spring.mail.* properties first.");
        }
        String resolvedRecipient = normalizeRecipient(recipientOverride, recipientEmail);
        if (resolvedRecipient.isBlank()) {
            throw new IllegalStateException("Measurement recipient email is not configured");
        }

        Path attachmentPath = Paths.get(generatedDocument.outputPath());
        if (!Files.exists(attachmentPath)) {
            throw new IllegalStateException("Generated measurement document not found: " + attachmentPath);
        }

        try {
            MimeMessage message = javaMailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, StandardCharsets.UTF_8.name());

            if (!fromAddress.isBlank()) {
                helper.setFrom(fromAddress);
            }
            helper.setTo(resolvedRecipient);
            String normalizedReplyTo = normalizeEmail(replyTo);
            if (!normalizedReplyTo.isBlank()) {
                helper.setReplyTo(normalizedReplyTo);
            }
            helper.setSubject(resolveSubject(caseId));
            helper.setText(buildBody(caseId, filledSlots), false);
            helper.addAttachment(generatedDocument.fileName(), attachmentPath.toFile());

            javaMailSender.send(message);
            String messageId = safeMessageId(message);
            Instant sentAt = Instant.now();

            log.info(
                    "neighbor-center mail sent caseId={} recipient={} fileName={} messageId={}",
                    caseId,
                    resolvedRecipient,
                    generatedDocument.fileName(),
                    messageId
            );
            return MailSendResult.sent(resolvedRecipient, resolveSubject(caseId), messageId, sentAt);
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to send neighbor-center measurement email", ex);
        }
    }

    private String normalizeRecipient(String overrideValue, String fallback) {
        String normalizedOverride = normalizeEmail(overrideValue);
        if (!normalizedOverride.isBlank()) {
            return normalizedOverride;
        }
        return normalizeEmail(fallback);
    }

    private String normalizeEmail(String value) {
        if (value == null) {
            return "";
        }
        String trimmed = value.trim();
        if (trimmed.isBlank() || !trimmed.contains("@")) {
            return "";
        }
        return trimmed;
    }

    private String resolveSubject(UUID caseId) {
        String subject = subjectTemplate.isBlank()
                ? "[정부24 데모] 층간소음 측정 신청서 제출"
                : subjectTemplate;
        return subject.replace("{caseId}", caseId.toString());
    }

    private String buildBody(UUID caseId, Map<String, Object> filledSlots) {
        String name = valueOrDefault(filledSlots, "name", "미입력");
        String phone = valueOrDefault(filledSlots, "phone", "미입력");
        String email = valueOrDefault(filledSlots, "email", "미입력");
        String address = valueOrDefault(filledSlots, "address", "미입력");
        String housingName = valueOrDefault(filledSlots, "housingName", "미입력");
        String startedAt = valueOrDefault(filledSlots, "startedAt", "미입력");
        String timeBand = valueOrDefault(filledSlots, "timeBand", "미입력");

        StringBuilder sb = new StringBuilder();
        sb.append("층간소음 측정 신청서 제출 메일입니다.\n\n");
        sb.append("케이스 ID: ").append(caseId).append("\n");
        sb.append("전송 시각: ").append(SENT_AT_FORMATTER.format(Instant.now())).append("\n\n");
        sb.append("[신청자 정보]\n");
        sb.append("- 성명: ").append(name).append("\n");
        sb.append("- 연락처: ").append(phone).append("\n");
        sb.append("- 이메일: ").append(email).append("\n");
        sb.append("- 주택명: ").append(housingName).append("\n");
        sb.append("- 주소: ").append(address).append("\n\n");
        sb.append("[소음 정보]\n");
        sb.append("- 시작 시점: ").append(startedAt).append("\n");
        sb.append("- 주 발생 시간: ").append(timeBand).append("\n\n");
        sb.append("첨부 파일(HWPX)을 확인해 주세요.");
        return sb.toString();
    }

    private String valueOrDefault(Map<String, Object> map, String key, String fallback) {
        if (map == null || map.isEmpty()) {
            return fallback;
        }
        Object value = map.get(key);
        if (value == null) {
            return fallback;
        }
        String text = value.toString().trim();
        return text.isBlank() ? fallback : text;
    }

    private String safeMessageId(MimeMessage message) {
        try {
            String messageId = message.getMessageID();
            return messageId == null ? "" : messageId;
        } catch (MessagingException ignored) {
            return "";
        }
    }

    public record MailSendResult(
            boolean sent,
            String recipient,
            String subject,
            String messageId,
            Instant sentAt
    ) {
        public static MailSendResult disabled() {
            return new MailSendResult(false, "", "", "", null);
        }

        public static MailSendResult sent(String recipient, String subject, String messageId, Instant sentAt) {
            return new MailSendResult(true, recipient, subject, messageId == null ? "" : messageId, sentAt);
        }
    }
}
