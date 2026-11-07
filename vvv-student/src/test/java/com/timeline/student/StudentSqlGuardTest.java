package com.timeline.student;

import com.timeline.student.persistence.StudentContentMapper;
import com.timeline.student.persistence.StudentDeviceMapper;
import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.junit.jupiter.api.Test;
import java.lang.reflect.Method;
import static org.junit.jupiter.api.Assertions.*;

/**
 * Static guard over the SQL text, no database needed. It is the executable form of two rules:
 *  1. the student app never reads a row that is not PUBLISHED;
 *  2. the content mapper is read-only and the device mapper never touches poetry_* tables.
 */
class StudentSqlGuardTest {

    @Test void everyPoetryQueryCarriesAPublishedCondition() {
        int checked = 0;
        for (Method m : StudentContentMapper.class.getDeclaredMethods()) {
            Select select = m.getAnnotation(Select.class);
            assertNotNull(select, m.getName() + " must be a @Select");
            String sql = String.join(" ", select.value());
            if (!sql.contains("poetry_")) continue;
            assertTrue(sql.contains("'PUBLISHED'"), m.getName() + " reads poetry_* without a PUBLISHED condition: " + sql);
            assertFalse(sql.toUpperCase().contains("'DRAFT'"), m.getName() + " must not mention DRAFT");
            checked++;
        }
        assertTrue(checked >= 5, "expected every content query to be checked, got " + checked);
    }

    @Test void contentMapperIsReadOnly() {
        for (Method m : StudentContentMapper.class.getDeclaredMethods()) {
            assertNull(m.getAnnotation(Insert.class), m.getName());
            assertNull(m.getAnnotation(Update.class), m.getName());
            assertNull(m.getAnnotation(Delete.class), m.getName());
        }
    }

    @Test void annotationQueryRequiresAPublicClaimAndAVerifiedSource() {
        String sql = selectOf(StudentContentMapper.class, "annotations");
        assertTrue(sql.contains("poetry_claim"));
        assertTrue(sql.contains("verification_status='VERIFIED'"));
        assertTrue(sql.contains("reviewed_by IS NOT NULL"));
    }

    @Test void lessonQueriesRequireACompiledBundle() {
        assertTrue(selectOf(StudentContentMapper.class, "latestLesson").contains("bundle_hash IS NOT NULL"));
        assertTrue(selectOf(StudentContentMapper.class, "publishedBundleCount").contains("bundle_hash IS NOT NULL"));
    }

    @Test void deviceMapperNeverReferencesTheContentBase() {
        for (Method m : StudentDeviceMapper.class.getDeclaredMethods()) {
            StringBuilder sql = new StringBuilder();
            if (m.getAnnotation(Select.class) != null) sql.append(String.join(" ", m.getAnnotation(Select.class).value()));
            if (m.getAnnotation(Insert.class) != null) sql.append(String.join(" ", m.getAnnotation(Insert.class).value()));
            if (m.getAnnotation(Update.class) != null) sql.append(String.join(" ", m.getAnnotation(Update.class).value()));
            if (m.getAnnotation(Delete.class) != null) sql.append(String.join(" ", m.getAnnotation(Delete.class).value()));
            assertFalse(sql.toString().contains("poetry_"), m.getName());
        }
    }

    @Test void deviceTablesHaveNoPersonalColumns() throws Exception {
        String raw = new String(getClass().getResourceAsStream("/db/student/S001__learning_records.sql").readAllBytes(),
            java.nio.charset.StandardCharsets.UTF_8);
        // The header comments name the banned things on purpose; only executable DDL is checked.
        StringBuilder code = new StringBuilder();
        for (String line : raw.split("\n")) {
            int dash = line.indexOf("--");
            code.append(dash >= 0 ? line.substring(0, dash) : line).append('\n');
        }
        String ddl = code.toString().toLowerCase();
        for (String banned : new String[] {" ip ", "ip_addr", "phone", "email", "real_name", "school", "imei", "idfa",
                "voice", "face", "recording", "latitude", "longitude", "retell_text", "free_text", "message"})
            assertFalse(ddl.contains(banned), "S001 must not contain a column like: " + banned);
        assertFalse(ddl.contains("foreign key"), "MySQL 5.6 project rule: no foreign keys");
        assertFalse(ddl.contains(" json"), "MySQL 5.6 has no JSON type");
        assertFalse(ddl.contains("check ("), "MySQL 5.6 ignores CHECK");
    }

    private static String selectOf(Class<?> type, String name) {
        for (Method m : type.getDeclaredMethods())
            if (m.getName().equals(name)) return String.join(" ", m.getAnnotation(Select.class).value());
        throw new AssertionError("no such method " + name);
    }
}
