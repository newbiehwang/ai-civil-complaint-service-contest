package com.contest.complaint.application;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

import javax.xml.XMLConstants;
import javax.xml.namespace.NamespaceContext;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;
import javax.xml.xpath.XPath;
import javax.xml.xpath.XPathConstants;
import javax.xml.xpath.XPathFactory;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.StringReader;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.LocalDateTime;
import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeFormatterBuilder;
import java.time.format.DateTimeParseException;
import java.time.temporal.ChronoField;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import java.util.zip.ZipOutputStream;

@Service
public class NeighborCenterMeasurementDocumentService {

    private static final Logger log = LoggerFactory.getLogger(NeighborCenterMeasurementDocumentService.class);

    private static final String HP_NS = "http://www.hancom.co.kr/hwpml/2011/paragraph";
    private static final String XML_DECL = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>";
    private static final ZoneId KST = ZoneId.of("Asia/Seoul");
    private static final DateTimeFormatter APPLY_DATE_FORMATTER =
            DateTimeFormatter.ofPattern("yyyy년 M월 d일", Locale.KOREAN);
    private static final DateTimeFormatter DIARY_DATETIME_FORMATTER =
            DateTimeFormatter.ofPattern("yyyy.MM.dd (E) HH:mm", Locale.KOREAN);
    private static final DateTimeFormatter ISO_LOCAL_DATETIME_FORMATTER =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss", Locale.ROOT);
    private static final DateTimeFormatter KOREAN_INPUT_DATETIME_FORMATTER =
            new DateTimeFormatterBuilder()
                    .appendPattern("yyyy년 M월 d일")
                    .optionalStart()
                    .appendLiteral(" ")
                    .appendLiteral("(")
                    .appendPattern("E")
                    .appendLiteral(")")
                    .optionalEnd()
                    .appendLiteral(" ")
                    .appendPattern("a hh시 mm분")
                    .parseDefaulting(ChronoField.SECOND_OF_MINUTE, 0)
                    .toFormatter(Locale.KOREAN);

    private final Path templatePath;
    private final Path outputDir;

    public NeighborCenterMeasurementDocumentService(
            @Value("${complaint.neighbor-center.measurement-template-path}") String templatePath,
            @Value("${complaint.neighbor-center.measurement-output-dir}") String outputDir
    ) {
        this.templatePath = Paths.get(templatePath);
        this.outputDir = Paths.get(outputDir);
    }

    public GeneratedMeasurementDocument generate(UUID caseId, Map<String, Object> filledSlots) {
        Objects.requireNonNull(caseId, "caseId");
        Map<String, Object> slots = filledSlots == null ? Map.of() : filledSlots;

        if (!Files.exists(templatePath)) {
            throw new IllegalStateException("Measurement template not found: " + templatePath);
        }

        try {
            Files.createDirectories(outputDir);

            Map<String, byte[]> entries = readZipEntries(templatePath);
            byte[] section0 = entries.get("Contents/section0.xml");
            if (section0 == null || section0.length == 0) {
                throw new IllegalStateException("Contents/section0.xml not found in template: " + templatePath);
            }

            Document document = parseSectionXml(section0);
            fillMeasurementApplication(document, slots);
            fillOccurrenceDiary(document, slots);

            byte[] serializedSection = serializeSectionXml(document);
            entries.put("Contents/section0.xml", serializedSection);

            String timestamp = DateTimeFormatter.ofPattern("yyyyMMdd-HHmmss", Locale.ROOT)
                    .withZone(ZoneId.of("Asia/Seoul"))
                    .format(Instant.now());
            String fileName = "neighbor-center-measurement-" + caseId + "-" + timestamp + ".hwpx";
            Path outputPath = outputDir.resolve(fileName);
            writeZipEntries(outputPath, entries);

            log.info(
                    "neighbor-center document generated caseId={} outputPath={} template={}",
                    caseId,
                    outputPath,
                    templatePath
            );

            return new GeneratedMeasurementDocument(
                    outputPath.toAbsolutePath().toString(),
                    fileName
            );
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to generate neighbor-center measurement document", ex);
        }
    }

    private void fillMeasurementApplication(Document document, Map<String, Object> slots) {
        String name = slot(slots, "name");
        String phone = slot(slots, "phone");
        String email = slot(slots, "email");
        String housingName = slot(slots, "housingName");
        String address = slot(slots, "address");
        String visitConsultWithin30Days = slot(slots, "visitConsultWithin30Days");
        String startedAt = slot(slots, "startedAt");
        String frequency = slot(slots, "frequency");
        String noiseNow = slot(slots, "noiseNow");
        String sourceCertainty = slot(slots, "sourceCertainty");
        String noiseType = joinListOrSingle(slots, "noiseTypes", "noiseType");
        String timeBand = joinListOrSingle(slots, "timeBands", "timeBand");

        String visitDateValue = firstNonBlank(slot(slots, "visitConsultDate"), visitConsultWithin30Days);
        String consultAfterStatus = composeConsultAfterStatus(frequency, timeBand, noiseNow, sourceCertainty);

        setCellText(document, 1, 1, 2, name);
        setCellText(document, 1, 1, 5, phone);
        setCellText(document, 1, 2, 2, email);
        setCellText(document, 1, 2, 5, housingName);
        setCellText(document, 1, 3, 2, address);
        setCellText(document, 1, 4, 2, visitDateValue);
        setCellText(document, 1, 5, 2, consultAfterStatus);
        setCellText(document, 1, 6, 2, noiseType);
        setCellText(document, 1, 7, 2, timeBand);

        String applyDate = APPLY_DATE_FORMATTER.format(LocalDateTime.ofInstant(Instant.now(), KST));
        String applySentence =
                "「층간소음 피해사례 조사·상담 등의 절차 및 방법에 관한 규정」제7조제1항에 따라 층간소음 측정을 신청합니다. "
                        + applyDate;
        setCellText(document, 1, 8, 0, applySentence);
        setCellText(document, 1, 9, 4, firstNonBlank(name, "(서명 또는 인)"));

        // Optional helper line for startedAt in case template has an additional blank data cell.
        setCellText(document, 1, 8, 2, firstNonBlank(startedAt, ""));
    }

    private void fillOccurrenceDiary(Document document, Map<String, Object> slots) {
        String name = slot(slots, "name");
        String phone = slot(slots, "phone");
        String address = slot(slots, "address");

        setCellText(document, 2, 1, 1, name);
        setCellText(document, 2, 1, 3, phone);
        setCellText(document, 2, 2, 1, address);

        List<OccurrenceRow> diaryRows = buildOccurrenceRows(slots);
        for (int row = 1; row <= 13; row++) {
            OccurrenceRow entry = row <= diaryRows.size() ? diaryRows.get(row - 1) : null;
            setCellText(document, 3, row, 0, entry == null ? "" : entry.occurredAt());
            setCellText(document, 3, row, 4, entry == null ? "" : entry.noiseType());
            setCellText(document, 3, row, 8, entry == null ? "" : entry.durationOrCount());
        }
    }

    private List<OccurrenceRow> buildOccurrenceRows(Map<String, Object> slots) {
        String startedAtRaw = firstNonBlank(
                slot(slots, "startedAt"),
                slot(slots, "startedAtDate")
        );

        LocalDateTime baseDateTime = parseStartedAt(startedAtRaw);
        if (baseDateTime == null) {
            baseDateTime = LocalDateTime.now(KST).minusDays(1).withHour(21).withMinute(0).withSecond(0).withNano(0);
        }

        List<String> noiseTypes = extractNoiseTypes(slots);
        if (noiseTypes.isEmpty()) {
            noiseTypes = List.of(firstNonBlank(slot(slots, "noiseType"), "층간소음"));
        }
        String noiseTypeCombined = String.join(", ", noiseTypes);

        List<String> timeBands = extractTimeBands(slots);
        int expectedRows = expectedDiaryRowCount(slot(slots, "frequency"));
        int totalRows = Math.max(expectedRows, timeBands.isEmpty() ? 1 : timeBands.size());
        totalRows = Math.min(totalRows, 13);

        List<OccurrenceRow> rows = new ArrayList<>();
        for (int i = 0; i < totalRows; i++) {
            String band = timeBands.isEmpty() ? "" : timeBands.get(i % timeBands.size());
            LocalDateTime occurredAt = applyTimeBand(baseDateTime.plusDays(i), band);
            rows.add(new OccurrenceRow(
                    DIARY_DATETIME_FORMATTER.format(occurredAt),
                    noiseTypeCombined,
                    durationFromFrequency(slot(slots, "frequency"))
            ));
        }
        return List.copyOf(rows);
    }

    private LocalDateTime parseStartedAt(String raw) {
        if (raw == null || raw.isBlank()) {
            return null;
        }
        String value = raw.trim();
        try {
            return LocalDateTime.ofInstant(Instant.parse(value), KST);
        } catch (DateTimeParseException ignored) {
            // try next format
        }
        try {
            return LocalDateTime.parse(value, KOREAN_INPUT_DATETIME_FORMATTER);
        } catch (DateTimeParseException ignored) {
            // try next format
        }
        try {
            return LocalDateTime.parse(value, ISO_LOCAL_DATETIME_FORMATTER);
        } catch (DateTimeParseException ignored) {
            return null;
        }
    }

    private LocalDateTime applyTimeBand(LocalDateTime dateTime, String timeBand) {
        String normalized = timeBand == null ? "" : timeBand.trim();
        if ("저녁".equals(normalized)) {
            return dateTime.withHour(20).withMinute(30).withSecond(0).withNano(0);
        }
        if ("심야".equals(normalized)) {
            return dateTime.withHour(23).withMinute(30).withSecond(0).withNano(0);
        }
        if ("새벽".equals(normalized)) {
            return dateTime.withHour(5).withMinute(30).withSecond(0).withNano(0);
        }
        return dateTime.withHour(19).withMinute(30).withSecond(0).withNano(0);
    }

    private List<String> extractNoiseTypes(Map<String, Object> slots) {
        return extractUniqueValues(slots, "noiseTypes", "noiseType");
    }

    private List<String> extractTimeBands(Map<String, Object> slots) {
        return extractUniqueValues(slots, "timeBands", "timeBand");
    }

    private List<String> extractUniqueValues(Map<String, Object> slots, String listKey, String singleKey) {
        LinkedHashSet<String> values = new LinkedHashSet<>();

        Object listObj = slots.get(listKey);
        if (listObj instanceof List<?> listValue) {
            for (Object item : listValue) {
                String normalized = normalizeValue(item);
                if (normalized != null) {
                    values.add(normalized);
                }
            }
        }

        String single = slot(slots, singleKey);
        if (!single.isBlank()) {
            String[] split = single.split("[,|/]");
            for (String token : split) {
                String normalized = normalizeValue(token);
                if (normalized != null) {
                    values.add(normalized);
                }
            }
        }
        return List.copyOf(values);
    }

    private String normalizeValue(Object raw) {
        if (raw == null) {
            return null;
        }
        String value = String.valueOf(raw).trim();
        return value.isBlank() ? null : value;
    }

    private int expectedDiaryRowCount(String frequency) {
        if ("거의 매일".equals(frequency)) {
            return 5;
        }
        if ("주 2~3회".equals(frequency)) {
            return 3;
        }
        if ("주 1회 이하".equals(frequency)) {
            return 2;
        }
        return 3;
    }

    private String durationFromFrequency(String frequency) {
        if ("거의 매일".equals(frequency)) {
            return "30분 이상";
        }
        if ("주 2~3회".equals(frequency)) {
            return "10~30분";
        }
        if ("주 1회 이하".equals(frequency)) {
            return "10분 미만";
        }
        return "간헐적 반복";
    }

    private String composeConsultAfterStatus(
            String frequency,
            String timeBand,
            String noiseNow,
            String sourceCertainty
    ) {
        List<String> parts = new ArrayList<>();
        if (frequency != null && !frequency.isBlank()) {
            parts.add("반복 빈도: " + frequency);
        }
        if (timeBand != null && !timeBand.isBlank()) {
            parts.add("시간대: " + timeBand);
        }
        if (noiseNow != null && !noiseNow.isBlank()) {
            parts.add("현재 상태: " + noiseNow);
        }
        if (sourceCertainty != null && !sourceCertainty.isBlank()) {
            parts.add("발생원 특정: " + sourceCertainty);
        }
        return String.join(" / ", parts);
    }

    private String joinListOrSingle(Map<String, Object> slots, String listKey, String singleKey) {
        Object listObj = slots.get(listKey);
        if (listObj instanceof List<?> listValue && !listValue.isEmpty()) {
            List<String> values = listValue.stream()
                    .map(String::valueOf)
                    .map(String::trim)
                    .filter(value -> !value.isBlank())
                    .toList();
            if (!values.isEmpty()) {
                return String.join(", ", values);
            }
        }
        return slot(slots, singleKey);
    }

    private String firstNonBlank(String... values) {
        if (values == null) {
            return "";
        }
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                return value;
            }
        }
        return "";
    }

    private String slot(Map<String, Object> slots, String key) {
        Object value = slots.get(key);
        if (value == null) {
            return "";
        }
        String normalized = String.valueOf(value).trim();
        return normalized.isBlank() ? "" : normalized;
    }

    private void setCellText(Document document, int tableIndex, int row, int col, String text) {
        Element cell = findCell(document, tableIndex, row, col);
        if (cell == null) {
            log.warn("HWPX cell not found table={} row={} col={}", tableIndex, row, col);
            return;
        }
        writeCellText(cell, text == null ? "" : text);
    }

    private Element findCell(Document document, int tableIndex, int row, int col) {
        try {
            XPath xpath = XPathFactory.newInstance().newXPath();
            xpath.setNamespaceContext(new HwpNamespaceContext());
            String expr = String.format(
                    "(//hp:tbl)[%d]/hp:tr/hp:tc[hp:cellAddr/@rowAddr='%d' and hp:cellAddr/@colAddr='%d']",
                    tableIndex,
                    row,
                    col
            );
            Node node = (Node) xpath.evaluate(expr, document, XPathConstants.NODE);
            if (node instanceof Element element) {
                return element;
            }
            return null;
        } catch (Exception ex) {
            throw new IllegalStateException("Failed to locate table cell", ex);
        }
    }

    private void writeCellText(Element cell, String text) {
        NodeList textNodes = cell.getElementsByTagNameNS(HP_NS, "t");
        if (textNodes.getLength() > 0) {
            Element first = (Element) textNodes.item(0);
            first.setTextContent(text);
            for (int i = textNodes.getLength() - 1; i >= 1; i--) {
                Node node = textNodes.item(i);
                Node parent = node.getParentNode();
                if (parent != null) {
                    parent.removeChild(node);
                }
            }
            return;
        }

        Element paragraph = findFirstChild(cell, "subList", "p");
        if (paragraph == null) {
            return;
        }

        Element run = findFirstChild(paragraph, "run");
        if (run == null) {
            run = paragraph.getOwnerDocument().createElementNS(HP_NS, "hp:run");
            paragraph.appendChild(run);
        }

        Element t = paragraph.getOwnerDocument().createElementNS(HP_NS, "hp:t");
        t.setTextContent(text);
        run.appendChild(t);
    }

    private Element findFirstChild(Element root, String... localNames) {
        Element current = root;
        for (String localName : localNames) {
            NodeList children = current.getElementsByTagNameNS(HP_NS, localName);
            if (children.getLength() == 0 || !(children.item(0) instanceof Element element)) {
                return null;
            }
            current = element;
        }
        return current;
    }

    private Document parseSectionXml(byte[] xmlBytes) throws Exception {
        DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
        factory.setNamespaceAware(true);
        factory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
        try {
            factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
            factory.setFeature("http://xml.org/sax/features/external-general-entities", false);
            factory.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
        } catch (Exception ignored) {
            // Best effort
        }
        DocumentBuilder builder = factory.newDocumentBuilder();
        return builder.parse(new InputSource(new StringReader(new String(xmlBytes, StandardCharsets.UTF_8))));
    }

    private byte[] serializeSectionXml(Document document) throws Exception {
        TransformerFactory tf = TransformerFactory.newInstance();
        tf.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
        Transformer transformer = tf.newTransformer();
        transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "no");
        transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
        transformer.setOutputProperty(OutputKeys.INDENT, "no");

        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        transformer.transform(new DOMSource(document), new StreamResult(baos));
        byte[] serialized = baos.toByteArray();

        String text = new String(serialized, StandardCharsets.UTF_8);
        if (!text.startsWith("<?xml")) {
            text = XML_DECL + text;
        }
        return text.getBytes(StandardCharsets.UTF_8);
    }

    private Map<String, byte[]> readZipEntries(Path zipPath) throws IOException {
        Map<String, byte[]> entries = new LinkedHashMap<>();
        try (ZipInputStream zis = new ZipInputStream(Files.newInputStream(zipPath))) {
            ZipEntry entry;
            while ((entry = zis.getNextEntry()) != null) {
                if (entry.isDirectory()) {
                    continue;
                }
                ByteArrayOutputStream baos = new ByteArrayOutputStream();
                zis.transferTo(baos);
                entries.put(entry.getName(), baos.toByteArray());
            }
        }
        return entries;
    }

    private void writeZipEntries(Path outputPath, Map<String, byte[]> entries) throws IOException {
        try (ZipOutputStream zos = new ZipOutputStream(Files.newOutputStream(outputPath))) {
            for (Map.Entry<String, byte[]> entry : entries.entrySet()) {
                ZipEntry zipEntry = new ZipEntry(entry.getKey());
                zos.putNextEntry(zipEntry);
                byte[] content = entry.getValue();
                if (content != null) {
                    zos.write(content);
                }
                zos.closeEntry();
            }
        }
    }

    public record GeneratedMeasurementDocument(
            String outputPath,
            String fileName
    ) {
    }

    private record OccurrenceRow(
            String occurredAt,
            String noiseType,
            String durationOrCount
    ) {
    }

    private static final class HwpNamespaceContext implements NamespaceContext {
        @Override
        public String getNamespaceURI(String prefix) {
            if ("hp".equals(prefix)) {
                return HP_NS;
            }
            return XMLConstants.NULL_NS_URI;
        }

        @Override
        public String getPrefix(String namespaceURI) {
            if (HP_NS.equals(namespaceURI)) {
                return "hp";
            }
            return null;
        }

        @Override
        public Iterator<String> getPrefixes(String namespaceURI) {
            if (HP_NS.equals(namespaceURI)) {
                return List.of("hp").iterator();
            }
            return List.<String>of().iterator();
        }
    }
}
