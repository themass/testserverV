package com.timeline.game.config;

import com.timeline.game.api.GameApiController;
import com.timeline.game.api.GameCommandSink;
import com.timeline.game.api.GameHandshakeInterceptor;
import com.timeline.game.api.GameWebSocketHandler;
import com.timeline.game.persistence.GameCoinLedgerMapper;
import com.timeline.game.persistence.GameMatchMapper;
import com.timeline.game.persistence.GameMatchPlayerMapper;
import com.timeline.game.persistence.GameProfileMapper;
import com.timeline.game.persistence.GameProgressMapper;
import com.timeline.game.persistence.GameSeasonMapper;
import com.timeline.game.persistence.GameWalletMapper;
import com.timeline.game.service.GameProfileService;
import com.timeline.game.service.GameSeasonService;
import com.timeline.game.service.GameSettlementService;
import com.timeline.game.service.GameWalletService;

import org.apache.ibatis.session.SqlSessionFactory;
import org.mybatis.spring.mapper.MapperFactoryBean;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.data.redis.core.StringRedisTemplate;

import java.time.Clock;
import java.time.ZoneId;

/**
 * 飞机对决游戏模块（库模块，随 vvv-link 进程装载）。
 *
 * 开启条件：game.enabled=true，且宿主有 SqlSessionFactory 与 Redis 连接。
 * 本类不跑迁移：db/game/*.sql 由人工按 docs/game/migration.md 执行（真库即线上库）。
 *
 * 属性（除 enabled 外全部可省）：
 *   game.enabled=true                  模块总开关
 *   game.ws.path=/api/game/ws          WebSocket 端点
 *   game.presenceTtlSeconds=90         在线态键 TTL
 *   game.commandRatePerMinute=1200     每连接命令令牌桶（约 20/s）
 *   game.seasonEnabled=false           赛季发奖/重置定时任务
 *
 * 接线顺序刻意保守：先 AutoConfiguration 空壳跑通宿主启动，再逐步挂
 * domain→persistence→realtime→service→api/ws（docs/game/design.md 待办顺序）。
 */
@AutoConfiguration(afterName = "org.mybatis.spring.boot.autoconfigure.MybatisAutoConfiguration")
@ConditionalOnBean(SqlSessionFactory.class)
@ConditionalOnProperty(prefix = "game", name = "enabled", havingValue = "true")
public class GameAutoConfiguration {

    /**
     * 身份解析：Vpn-Token → Redis token_%s → vpn.user.id。
     * 用 StringRedisTemplate 直读宿主的 token 缓存，不依赖 vvv-link 类（库模块不反向依赖进程模块）。
     */
    @Bean
    public GameTokenResolver gameTokenResolver(StringRedisTemplate redis) {
        return new GameTokenResolver(redis);
    }

    /** 标记 Bean：确认模块真的装上了（logs 里 grep 它）。 */
    @Bean
    public GameModuleMarker gameModuleMarker() {
        return new GameModuleMarker();
    }

    // ---------------------------------------------------------------- 持久层
    // 七个 mapper 挂宿主 SqlSessionFactory（同 vvv-student 的接法）：
    // 库模块不 @MapperScan——扫包会越界到宿主其它 mapper 的注册策略。

    @Bean
    public MapperFactoryBean<GameProfileMapper> gameProfileMapper(SqlSessionFactory factory) {
        MapperFactoryBean<GameProfileMapper> bean = new MapperFactoryBean<>(GameProfileMapper.class);
        bean.setSqlSessionFactory(factory);
        return bean;
    }

    @Bean
    public MapperFactoryBean<GameProgressMapper> gameProgressMapper(SqlSessionFactory factory) {
        MapperFactoryBean<GameProgressMapper> bean = new MapperFactoryBean<>(GameProgressMapper.class);
        bean.setSqlSessionFactory(factory);
        return bean;
    }

    @Bean
    public MapperFactoryBean<GameWalletMapper> gameWalletMapper(SqlSessionFactory factory) {
        MapperFactoryBean<GameWalletMapper> bean = new MapperFactoryBean<>(GameWalletMapper.class);
        bean.setSqlSessionFactory(factory);
        return bean;
    }

    @Bean
    public MapperFactoryBean<GameCoinLedgerMapper> gameCoinLedgerMapper(SqlSessionFactory factory) {
        MapperFactoryBean<GameCoinLedgerMapper> bean = new MapperFactoryBean<>(GameCoinLedgerMapper.class);
        bean.setSqlSessionFactory(factory);
        return bean;
    }

    @Bean
    public MapperFactoryBean<GameMatchMapper> gameMatchMapper(SqlSessionFactory factory) {
        MapperFactoryBean<GameMatchMapper> bean = new MapperFactoryBean<>(GameMatchMapper.class);
        bean.setSqlSessionFactory(factory);
        return bean;
    }

    @Bean
    public MapperFactoryBean<GameMatchPlayerMapper> gameMatchPlayerMapper(SqlSessionFactory factory) {
        MapperFactoryBean<GameMatchPlayerMapper> bean = new MapperFactoryBean<>(GameMatchPlayerMapper.class);
        bean.setSqlSessionFactory(factory);
        return bean;
    }

    @Bean
    public MapperFactoryBean<GameSeasonMapper> gameSeasonMapper(SqlSessionFactory factory) {
        MapperFactoryBean<GameSeasonMapper> bean = new MapperFactoryBean<>(GameSeasonMapper.class);
        bean.setSqlSessionFactory(factory);
        return bean;
    }

    // ---------------------------------------------------------------- 公共时钟

    /**
     * 逻辑时间统一从这里注入（spec §1 禁墙钟令的执行方式）：生产用系统时钟，
     * 测试直接 new 服务传固定时钟，不经 Spring。
     */
    @Bean
    public Clock gameClock() {
        return Clock.systemUTC();
    }

    /** 日切时区（Coins.dayKey 的口径）。默认东八区——真库用户全在国内。 */
    @Bean
    public ZoneId gameZone(@Value("${game.zone:Asia/Shanghai}") String zone) {
        return ZoneId.of(zone);
    }

    // ---------------------------------------------------------------- 服务层

    @Bean
    public GameWalletService gameWalletService(GameWalletMapper wallet, GameCoinLedgerMapper ledger) {
        return new GameWalletService(wallet, ledger);
    }

    @Bean
    public GameSettlementService gameSettlementService(GameMatchMapper match,
                                                       GameMatchPlayerMapper matchPlayer,
                                                       GameProgressMapper progress,
                                                       GameProfileMapper profile,
                                                       GameWalletService wallet, ZoneId zone) {
        return new GameSettlementService(match, matchPlayer, progress, profile, wallet, zone);
    }

    @Bean
    public GameSeasonService gameSeasonService(GameProgressMapper progress, GameSeasonMapper season,
                                               GameWalletService wallet, ZoneId zone) {
        return new GameSeasonService(progress, season, wallet, zone);
    }

    @Bean
    public GameProfileService gameProfileService(GameProfileMapper profile, GameProgressMapper progress,
                                                 GameWalletMapper wallet, GameCoinLedgerMapper ledger,
                                                 GameMatchMapper match, GameSeasonService seasons,
                                                 ZoneId zone) {
        return new GameProfileService(profile, progress, wallet, ledger, match, seasons, zone);
    }

    // ---------------------------------------------------------------- HTTP

    @Bean
    public GameApiController gameApiController(GameTokenResolver tokens, GameProfileService profiles,
                                               ZoneId zone, Clock clock) {
        return new GameApiController(tokens, profiles, zone, clock);
    }

    // ---------------------------------------------------------------- WS 接入

    /**
     * WS 三件套（握手鉴权 → 传输层 → 端点注册）。整组挂在 GameCommandSink（=GameHub）上：
     * 业务路由器注册之前 WS 面不装载，HTTP 读接口与 /health 仍可先行自检。
     */
    @org.springframework.context.annotation.Import(GameWebSocketConfiguration.class)
    static class GameWsImports { }

    @org.springframework.web.socket.config.annotation.EnableWebSocket
    @ConditionalOnBean(GameCommandSink.class)
    static class GameWebSocketConfiguration
        implements org.springframework.web.socket.config.annotation.WebSocketConfigurer {

        private final GameWebSocketHandler handler;
        private final GameHandshakeInterceptor interceptor;
        private final String path;
        private final String allowedOrigins;

        GameWebSocketConfiguration(GameWebSocketHandler handler, GameHandshakeInterceptor interceptor,
                                   @Value("${game.ws.path:/api/game/ws}") String path,
                                   @Value("${game.ws.allowed-origins:*}") String allowedOrigins) {
            this.handler = handler;
            this.interceptor = interceptor;
            this.path = path;
            this.allowedOrigins = allowedOrigins;
        }

        @Override
        public void registerWebSocketHandlers(
            org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry registry) {
            java.util.List<String> origins = java.util.Arrays.stream(allowedOrigins.split(","))
                .map(String::trim).filter(s -> !s.isEmpty()).toList();
            if (origins.isEmpty()) origins = java.util.List.of("*");
            // TS 版 wss 无同源检查（客户端是 App）；收紧走 game.ws.allowed-origins，默认放开等价旧行为。
            registry.addHandler(handler, path)
                .addInterceptors(interceptor)
                .setAllowedOriginPatterns(origins.toArray(String[]::new));
        }
    }

    @Bean
    @ConditionalOnBean(GameCommandSink.class)
    public GameHandshakeInterceptor gameHandshakeInterceptor(GameTokenResolver tokens) {
        return new GameHandshakeInterceptor(tokens);
    }

    @Bean
    @ConditionalOnBean(GameCommandSink.class)
    public GameWebSocketHandler gameWebSocketHandler(
        GameCommandSink sink, @Value("${game.commandRatePerMinute:1200}") int rate) {
        return new GameWebSocketHandler(new com.fasterxml.jackson.databind.ObjectMapper(), sink, rate);
    }
}
