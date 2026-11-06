package com.timeline.poetry.service;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import javax.sql.DataSource;
import org.springframework.jdbc.datasource.DataSourceUtils;

/**
 * Runs audit_integrity_checks.sql (one statement) and returns the rows that are not zero.
 * The write side calls this before any publish, so the same 106 checks that a human runs by
 * hand are also the machine's publish precondition. There is no second copy of the rules.
 */
public class AuditRunner {
    public static final String AUDIT_RESOURCE = "db/poetry/audit_integrity_checks.sql";
    private final DataSource dataSource;
    public AuditRunner(DataSource dataSource) { this.dataSource = dataSource; }

    public record Result(int totalChecks, List<String> nonZero) {
        public boolean clean() { return nonZero.isEmpty(); }
    }

    public Result run() {
        String sql = statement();
        List<String> bad = new ArrayList<>();
        int total = 0;
        // DataSourceUtils, not dataSource.getConnection(): inside @Transactional the audit must
        // run on the SAME connection, otherwise it cannot see the write it is supposed to police.
        Connection c = DataSourceUtils.getConnection(dataSource);
        try (Statement st = c.createStatement(); ResultSet rs = st.executeQuery(sql)) {
            while (rs.next()) { total++; if (rs.getLong(2) != 0) bad.add(rs.getString(1) + "=" + rs.getLong(2)); }
        } catch (Exception ex) {
            return new Result(0, List.of("audit could not run: " + ex.getClass().getSimpleName()));
        } finally {
            DataSourceUtils.releaseConnection(c, dataSource);
        }
        return new Result(total, List.copyOf(bad));
    }

    private String statement() {
        try (InputStream in = AuditRunner.class.getClassLoader().getResourceAsStream(AUDIT_RESOURCE)) {
            if (in == null) throw new IllegalStateException(AUDIT_RESOURCE + " missing from classpath");
            StringBuilder body = new StringBuilder();
            for (String line : new String(in.readAllBytes(), StandardCharsets.UTF_8).split("\n")) {
                if (line.trim().startsWith("--")) continue;
                body.append(line).append('\n');
            }
            String sql = body.toString().trim();
            return sql.endsWith(";") ? sql.substring(0, sql.length() - 1) : sql;
        } catch (RuntimeException ex) { throw ex; }
        catch (Exception ex) { throw new IllegalStateException("cannot read " + AUDIT_RESOURCE, ex); }
    }
}
