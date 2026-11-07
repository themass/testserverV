package com.timeline.student.api;

import com.timeline.student.api.StudentModels.*;
import com.timeline.student.domain.StudentErrors.Unauthorized;
import com.timeline.student.domain.StudentErrors.Unavailable;
import com.timeline.student.service.DeviceService;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import java.security.MessageDigest;
import java.nio.charset.StandardCharsets;
import java.util.List;

/**
 * Anonymous device + learning records. Bearer auth only: no cookie, no session, no identity.
 * `internal/*` is for the content team's gap board and needs a separate token that is blank by default,
 * which keeps it closed (503) until an operator sets it.
 */
@RestController
@RequestMapping("/api/student/v1")
public class StudentDeviceController {
    public static final String INTERNAL_HEADER = "X-Student-Internal-Token";
    private final DeviceService devices;
    private final String internalToken;

    public StudentDeviceController(DeviceService devices, String internalToken) {
        this.devices = devices; this.internalToken = internalToken;
    }

    @PostMapping("/devices")
    public Response<DeviceCreated> create() { return Response.ok(devices.create()); }

    @GetMapping("/devices/me")
    public Response<DeviceInfo> me(@RequestHeader(name = "Authorization", required = false) String auth) {
        return Response.ok(devices.info(devices.authenticate(auth)));
    }

    @DeleteMapping("/devices/me")
    public Response<Accepted> delete(@RequestHeader(name = "Authorization", required = false) String auth) {
        devices.deleteAll(devices.authenticate(auth));
        return Response.ok(new Accepted(1));
    }

    @GetMapping("/devices/me/sessions")
    public Response<List<SessionView>> sessions(@RequestHeader(name = "Authorization", required = false) String auth) {
        return Response.ok(devices.sessions(devices.authenticate(auth)));
    }

    @PutMapping("/devices/me/sessions/{workId}")
    public Response<Accepted> putSession(@RequestHeader(name = "Authorization", required = false) String auth,
                                         @PathVariable String workId, @RequestBody SessionWrite body) {
        devices.putSession(devices.authenticate(auth), workId, body);
        return Response.ok(new Accepted(1));
    }

    @PostMapping("/devices/me/events")
    public Response<Accepted> events(@RequestHeader(name = "Authorization", required = false) String auth,
                                     @RequestBody List<EventIn> body) {
        return Response.ok(devices.events(devices.authenticate(auth), body));
    }

    @PostMapping("/devices/me/gaps")
    public Response<Accepted> gaps(@RequestHeader(name = "Authorization", required = false) String auth,
                                   @RequestBody GapIn body) {
        return Response.ok(devices.gaps(devices.authenticate(auth), body));
    }

    @GetMapping("/internal/gaps")
    public Response<Board> board(@RequestHeader(name = INTERNAL_HEADER, required = false) String provided,
                                 @RequestParam String workId, @RequestParam String scriptHash) {
        if (internalToken == null || internalToken.isBlank())
            throw new Unavailable("student.internalToken is not configured: the gap board stays closed");
        if (provided == null || !MessageDigest.isEqual(provided.getBytes(StandardCharsets.UTF_8),
                internalToken.getBytes(StandardCharsets.UTF_8))) throw new Unauthorized("invalid or missing " + INTERNAL_HEADER);
        return Response.ok(devices.board(workId, scriptHash));
    }
}
