package com.timeline.student.service;

import com.timeline.student.api.StudentModels.*;
import com.timeline.student.domain.StudentErrors.BadRequest;
import com.timeline.student.domain.StudentErrors.Unauthorized;
import com.timeline.student.persistence.StudentDeviceMapper;
import com.timeline.student.persistence.StudentDeviceMapper.DeviceRow;
import org.springframework.transaction.annotation.Transactional;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.Base64;
import java.util.HexFormat;
import java.util.List;
import static com.timeline.student.domain.StudentVocabulary.*;

/**
 * Anonymous devices and their learning records.
 *
 * Authentication is a bearer key looked up by SHA-256. The key is 256 random bits, so a fast hash is
 * adequate (there is nothing to brute-force). The key itself is never stored or logged.
 * There is no name, email, phone or any other identity anywhere in this class.
 */
public class DeviceService {
    private static final SecureRandom RANDOM = new SecureRandom();
    private final StudentDeviceMapper mapper;
    private final String dataNoticeVersion;

    public DeviceService(StudentDeviceMapper mapper, String dataNoticeVersion) {
        this.mapper = mapper; this.dataNoticeVersion = dataNoticeVersion;
    }

    public String dataNoticeVersion() { return dataNoticeVersion; }

    @Transactional
    public DeviceCreated create() {
        String id = token(18);       // 144 bits -> 24 chars
        String key = token(32);      // 256 bits -> 43 chars
        mapper.insertDevice(id, sha256(key), "PRIMARY", dataNoticeVersion);
        return new DeviceCreated(id, key, dataNoticeVersion);
    }

    /** Header value "Bearer <key>" -> the device row, or Unauthorized. Never reveals why. */
    public DeviceRow authenticate(String authorization) {
        if (authorization == null || !authorization.startsWith("Bearer ")) throw new Unauthorized("missing or invalid credentials");
        String key = authorization.substring(7).trim();
        if (key.length() < 20 || key.length() > 128) throw new Unauthorized("missing or invalid credentials");
        DeviceRow row = mapper.deviceByKey(sha256(key));
        if (row == null) throw new Unauthorized("missing or invalid credentials");
        mapper.touchDevice(row.id());
        return row;
    }

    public DeviceInfo info(DeviceRow row) {
        return new DeviceInfo(row.id(), row.audience(), row.createdAt(), row.consentVersion());
    }

    @Transactional
    public void putSession(DeviceRow device, String workId, SessionWrite in) {
        if (workId == null || !ID.matcher(workId).matches()) throw new BadRequest("workId");
        SessionWrite clean = EventValidator.session(in);
        mapper.upsertSession(device.id(), workId, clean.lastStep(), String.join(",", clean.visited()), clean.audience());
        mapper.setAudience(device.id(), clean.audience());
    }

    public List<SessionView> sessions(DeviceRow device) {
        return mapper.sessions(device.id()).stream().map(r -> new SessionView(r.workId(), r.lastStep(),
            r.visited() == null || r.visited().isBlank() ? List.of() : List.of(r.visited().split(",")),
            r.audience(), r.enteredAt(), r.updatedAt())).toList();
    }

    @Transactional
    public Accepted events(DeviceRow device, List<EventIn> batch) {
        List<EventValidator.Clean> clean = EventValidator.events(batch, Instant.now());
        for (EventValidator.Clean e : clean)
            mapper.insertEvent(device.id(), e.workId(), e.step(), e.kind(), e.ref(), e.ms(), e.clientAt());
        return new Accepted(clean.size());
    }

    @Transactional
    public Accepted gaps(DeviceRow device, GapIn in) {
        GapIn clean = EventValidator.gaps(in);
        int n = 0;
        for (String p : clean.covered()) { mapper.insertGap(device.id(), clean.workId(), clean.scriptHash(), p, "COVERED"); n++; }
        for (String p : clean.missing()) { mapper.insertGap(device.id(), clean.workId(), clean.scriptHash(), p, "MISSING"); n++; }
        return new Accepted(n);
    }

    /** "Reset my identity" and "parent: delete my child's data" are the same operation. */
    @Transactional
    public void deleteAll(DeviceRow device) {
        mapper.deleteEvents(device.id());
        mapper.deleteGaps(device.id());
        mapper.deleteSessions(device.id());
        mapper.deleteDevice(device.id());
    }

    /** Aggregated per point; refuses to show numbers for a handful of devices (small-group disclosure). */
    public Board board(String workId, String scriptHash) {
        if (workId == null || !ID.matcher(workId).matches()) throw new BadRequest("workId");
        if (scriptHash == null || !SCRIPT_HASH.matcher(scriptHash).matches()) throw new BadRequest("scriptHash");
        int devices = mapper.boardDevices(workId, scriptHash);
        if (devices < MIN_BOARD_DEVICES) return new Board(workId, scriptHash, false, devices, List.of());
        List<BoardPoint> points = mapper.board(workId, scriptHash).stream()
            .map(r -> new BoardPoint(r.pointId(), r.coveredDevices(), r.missingDevices())).toList();
        return new Board(workId, scriptHash, true, devices, points);
    }

    static String token(int bytes) {
        byte[] b = new byte[bytes];
        RANDOM.nextBytes(b);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(b);
    }

    static String sha256(String value) {
        try {
            return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException ex) {
            throw new IllegalStateException(ex);
        }
    }
}
