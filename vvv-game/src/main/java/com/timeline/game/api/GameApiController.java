package com.timeline.game.api;

import com.timeline.game.config.GameTokenResolver;
import com.timeline.game.service.GameProfileService;
import com.timeline.game.protocol.GameErrorCode;

import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.Clock;
import java.time.ZoneId;
import java.util.Map;

/**
 * /api/game/v1/**（docs/game/api.md）：打开 App 先拉一次的读接口 + 离线写（昵称、广告）。
 * 实时操作只走 WS，这里刻意不提供 HTTP 版（避免两份实现漂移）。
 *
 * 鉴权：请求头 Vpn-Token（与 vvv-link 同一 Redis 校验链路）；解不出 → errno=NOT_AUTHED。
 * 本控制器只挂在 game.enabled=true 的 AutoConfiguration 下，默认不上线。
 */
@RestController
@RequestMapping("/api/game/v1")
public class GameApiController {

    private final GameTokenResolver tokens;
    private final GameProfileService profiles;
    private final ZoneId zone;
    private final Clock clock;

    public GameApiController(GameTokenResolver tokens, GameProfileService profiles,
                             ZoneId zone, Clock clock) {
        this.tokens = tokens;
        this.profiles = profiles;
        this.zone = zone;
        this.clock = clock;
    }

    private long nowMs() { return clock.millis(); }

    /** 解 token；未登录返回 null（调用方回 NOT_AUTHED）。 */
    private GameTokenResolver.PlatformUser authed(HttpServletRequest request) {
        String token = request.getHeader(GameHandshakeInterceptor.HEADER);
        if (token == null || token.isBlank()) token = request.getParameter("vpnToken");
        return tokens.resolve(token);
    }

    @GetMapping("/profile")
    public GameResponse<GameProfileService.ProfileView> profile(HttpServletRequest http) {
        var user = authed(http);
        if (user == null) return unauthorized();
        return GameResponse.ok(profiles.profile(user.userId(), user.name(), nowMs()));
    }

    @PutMapping("/nickname")
    public GameResponse<GameProfileService.ProfileView> nickname(HttpServletRequest http,
                                                                 @RequestBody Map<String, Object> body) {
        var user = authed(http);
        if (user == null) return unauthorized();
        var err = profiles.setNickname(user.userId(), body.get("nickname"));
        if (err != null) return GameResponse.fail(err, null);
        return GameResponse.ok(profiles.profile(user.userId(), user.name(), nowMs()));
    }

    @GetMapping("/coins/ledger")
    public GameResponse<GameProfileService.LedgerView> ledger(HttpServletRequest http) {
        var user = authed(http);
        if (user == null) return unauthorized();
        return GameResponse.ok(profiles.coinsLedger(user.userId()));
    }

    @PostMapping("/coins/ad-reward")
    public GameResponse<Map<String, Object>> adReward(HttpServletRequest http,
                                                      @RequestBody(required = false) Map<String, Object> body) {
        var user = authed(http);
        if (user == null) return unauthorized();
        // adRef 参与幂等键扩展位（当前词表只用 day:序号；留参给渠道回执对账，不落库）
        var r = profiles.adReward(user.userId(), nowMs());
        if (r.error() != null) return GameResponse.fail(r.error(), null);
        return GameResponse.ok(Map.of("granted", r.granted(), "balance", r.balance()));
    }

    @GetMapping("/rank/list")
    public GameResponse<java.util.List<GameProfileService.RankRowEntry>> rankList(
        HttpServletRequest http, @RequestParam(value = "limit", defaultValue = "100") int limit) {
        var user = authed(http);
        if (user == null) return unauthorized();
        return GameResponse.ok(profiles.rankList(limit, nowMs()));
    }

    @GetMapping("/matches/recent")
    public GameResponse<java.util.List<GameProfileService.MatchBrief>> recent(
        HttpServletRequest http, @RequestParam(value = "limit", defaultValue = "20") int limit) {
        var user = authed(http);
        if (user == null) return unauthorized();
        return GameResponse.ok(profiles.recentMatches(user.userId(), limit));
    }

    /** 自检（无鉴权）：模块装了没、Redis/MySQL 是否读得通——只回布尔，不泄露配置。 */
    @GetMapping("/health")
    public GameResponse<Map<String, Object>> health() {
        boolean db;
        try {
            profiles.rankList(1, nowMs());
            db = true;
        } catch (RuntimeException e) {
            db = false;
        }
        boolean redis;
        try {
            redis = tokens.redisAlive();
        } catch (RuntimeException e) {
            redis = false;
        }
        return GameResponse.ok(Map.of("module", true, "mysql", db, "redis", redis));
    }

    private static <T> GameResponse<T> unauthorized() {
        return new GameResponse<>(401, null, GameErrorCode.NOT_AUTHED.name());
    }
}
