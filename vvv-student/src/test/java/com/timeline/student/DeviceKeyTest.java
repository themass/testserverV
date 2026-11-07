package com.timeline.student;

import com.timeline.student.api.StudentCorsFilter;
import com.timeline.student.domain.StudentErrors.Unauthorized;
import com.timeline.student.persistence.StudentDeviceMapper;
import com.timeline.student.persistence.StudentDeviceMapper.DeviceRow;
import com.timeline.student.service.DeviceService;
import org.junit.jupiter.api.Test;
import java.lang.reflect.Proxy;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import static org.junit.jupiter.api.Assertions.*;

/** Uses a recording stub for the mapper: no database, no Spring. */
class DeviceKeyTest {

    /** Records the arguments of every mapper call by method name. */
    private static final class Recorder {
        final List<String> calls = new ArrayList<>();
        final List<Object[]> args = new ArrayList<>();
        DeviceRow stored;

        StudentDeviceMapper mapper() {
            return (StudentDeviceMapper) Proxy.newProxyInstance(getClass().getClassLoader(),
                new Class<?>[] {StudentDeviceMapper.class}, (proxy, method, a) -> {
                    calls.add(method.getName());
                    args.add(a);
                    if (method.getName().equals("deviceByKey")) return stored;
                    return method.getReturnType() == int.class ? 1 : null;
                });
        }
    }

    @Test void createdKeyIsLongRandomAndOnlyItsHashIsStored() {
        Recorder rec = new Recorder();
        DeviceService service = new DeviceService(rec.mapper(), "2026-11-06");
        var created = service.create();

        assertTrue(created.deviceKey().length() >= 43, "256 random bits, url-safe base64");
        assertTrue(created.deviceId().length() >= 24 && created.deviceId().length() <= 32);
        assertEquals("insertDevice", rec.calls.get(0));
        String storedHash = (String) rec.args.get(0)[1];
        assertEquals(64, storedHash.length());
        assertNotEquals(created.deviceKey(), storedHash);
        for (Object arg : rec.args.get(0)) assertNotEquals(created.deviceKey(), arg, "the key must never be stored");
    }

    @Test void keysAreUnique() {
        Recorder rec = new Recorder();
        DeviceService service = new DeviceService(rec.mapper(), "n");
        Set<String> keys = new HashSet<>(), ids = new HashSet<>();
        for (int i = 0; i < 200; i++) { var c = service.create(); keys.add(c.deviceKey()); ids.add(c.deviceId()); }
        assertEquals(200, keys.size());
        assertEquals(200, ids.size());
    }

    @Test void authenticationLooksUpByHashAndRejectsEverythingElseWithTheSameMessage() {
        Recorder rec = new Recorder();
        DeviceService service = new DeviceService(rec.mapper(), "n");
        var created = service.create();
        rec.stored = new DeviceRow(created.deviceId(), "PRIMARY", "n", "2026-11-06T00:00:00Z");

        assertEquals(created.deviceId(), service.authenticate("Bearer " + created.deviceKey()).id());
        String lookedUp = (String) rec.args.get(rec.calls.lastIndexOf("deviceByKey"))[0];
        assertEquals(64, lookedUp.length());

        rec.stored = null;
        for (String bad : new String[] {null, "", "Bearer", "Bearer ", "Bearer short", "Basic abc", "bearer " + created.deviceKey(),
                "Bearer " + "x".repeat(200)}) {
            Unauthorized ex = assertThrows(Unauthorized.class, () -> service.authenticate(bad), String.valueOf(bad));
            assertEquals("missing or invalid credentials", ex.getMessage());
        }
    }

    @Test void deletingADeviceRemovesEveryDependantBeforeTheDevice() {
        Recorder rec = new Recorder();
        DeviceService service = new DeviceService(rec.mapper(), "n");
        service.deleteAll(new DeviceRow("dev-1", "PRIMARY", "n", "t"));
        assertEquals(List.of("deleteEvents", "deleteGaps", "deleteSessions", "deleteDevice"), rec.calls);
    }

    @Test void gapBoardRefusesToShowNumbersForAHandfulOfDevices() {
        StudentDeviceMapper few = (StudentDeviceMapper) Proxy.newProxyInstance(getClass().getClassLoader(),
            new Class<?>[] {StudentDeviceMapper.class}, (p, m, a) -> m.getName().equals("boardDevices") ? 4
                : m.getName().equals("board") ? List.of(new StudentDeviceMapper.BoardRow("p-home", 1, 3)) : null);
        var board = new DeviceService(few, "n").board("work-chun-wang", "60279d333bec");
        assertFalse(board.enoughData());
        assertTrue(board.points().isEmpty());

        StudentDeviceMapper enough = (StudentDeviceMapper) Proxy.newProxyInstance(getClass().getClassLoader(),
            new Class<?>[] {StudentDeviceMapper.class}, (p, m, a) -> m.getName().equals("boardDevices") ? 5
                : m.getName().equals("board") ? List.of(new StudentDeviceMapper.BoardRow("p-home", 1, 4)) : null);
        var shown = new DeviceService(enough, "n").board("work-chun-wang", "60279d333bec");
        assertTrue(shown.enoughData());
        assertEquals(1, shown.points().size());
    }

    @Test void corsReflectsOnlyListedOriginsAndSupportsPerAppWildcards() throws Exception {
        var filter = new StudentCorsFilter(Set.of("capacitor://localhost", "https://*.appid.localhost"));
        var matches = StudentCorsFilter.class.getDeclaredMethod("matches", String.class);
        matches.setAccessible(true);
        assertTrue((boolean) matches.invoke(filter, "capacitor://localhost"));
        assertTrue((boolean) matches.invoke(filter, "https://poetry.appid.localhost"));
        assertFalse((boolean) matches.invoke(filter, "https://appid.localhost.evil.com"));
        assertFalse((boolean) matches.invoke(filter, "https://.appid.localhost"));
        assertFalse((boolean) matches.invoke(filter, "http://evil.example"));
        assertFalse((boolean) matches.invoke(filter, "null"));
    }
}
