package com.timeline.poetry.service;

import com.timeline.poetry.domain.Vocabulary;
import com.timeline.poetry.persistence.PoetryMapper;
import org.springframework.boot.context.event.ApplicationReadyEvent;
import org.springframework.context.ApplicationListener;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;

/**
 * Startup self-check. The module never runs migrations, so the two ways it can be quietly
 * broken are: the poetry_* tables do not exist in this schema, or the Java vocabularies and
 * the SQL audit vocabularies have drifted apart. Both are reported once at startup and can
 * be re-read at any time through {@link #report()}. Nothing here throws: a misconfigured
 * poetry module must not take the host application down.
 */
public class PoetrySelfCheck implements ApplicationListener<ApplicationReadyEvent> {
    private static final String AUDIT_RESOURCE = "db/poetry/audit_integrity_checks.sql";
    private final PoetryMapper mapper;
    private volatile String report = "self-check has not run yet";

    public PoetrySelfCheck(PoetryMapper mapper) { this.mapper = mapper; }

    @Override public void onApplicationEvent(ApplicationReadyEvent event) { run(); }

    public synchronized String run() {
        List<String> problems = new ArrayList<>();
        StringBuilder out = new StringBuilder();
        try {
            Integer rows = mapper.contentRowCount();
            Integer version = mapper.maxSchemaVersion();
            out.append("tables reachable: poetry_content rows=").append(rows)
               .append(", schema_version=").append(version);
            if (version == null || version < 7) problems.add("schema_version looks older than V004");
        } catch (Exception ex) {
            problems.add("poetry tables are NOT reachable (" + ex.getClass().getSimpleName()
                + "). Apply db/poetry/V001..V007 on this schema, or set poetry.enabled=false.");
        }
        String audit = readClasspath(AUDIT_RESOURCE);
        if (audit == null) problems.add("audit SQL missing from classpath: " + AUDIT_RESOURCE);
        else {
            List<String> missing = new ArrayList<>();
            Vocabulary.all().forEach((name, words) -> words.stream()
                .filter(w -> !audit.contains("'" + w + "'")).forEach(w -> missing.add(name + "=" + w)));
            if (!missing.isEmpty())
                problems.add("Java vocabularies not found in audit SQL (drift): " + String.join(", ", missing));
            else out.append(", vocabularies match audit SQL");
        }
        report = out + (problems.isEmpty() ? " | OK" : " | PROBLEMS: " + String.join(" ; ", problems));
        if (problems.isEmpty()) System.out.println("[poetry] self-check OK -> " + out);
        else System.err.println("[poetry] self-check FAILED -> " + report);
        return report;
    }

    public String report() { return report; }

    private static String readClasspath(String path) {
        try (InputStream in = PoetrySelfCheck.class.getClassLoader().getResourceAsStream(path)) {
            return in == null ? null : new String(in.readAllBytes(), StandardCharsets.UTF_8);
        } catch (Exception ex) { return null; }
    }
}
