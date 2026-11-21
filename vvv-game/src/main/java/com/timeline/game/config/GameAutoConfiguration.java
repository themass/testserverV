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
import com.timeline.game.service.GameHub;
import com.timeline.game.service.GameProfileService;
import com.timeline.game.service.GameSeasonService;
import com.timeline.game.service.GameSettlementService;
import com.timeline.game.service.GameWalletService;
import com.timeline.game.service.Matchmaking;

import org.apache.ibatis.session.SqlSessionFactory;
import org.mybatis.spring.mapper.MapperFactoryBean;
import org.springframework.beans.factory.DisposableBean;
import org.springframework.beans.factory.ObjectProvider;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;

import java.time.Clock;
import java.time.ZoneId;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

/**
 * 飞机对决游戏模块（库模块，随 vvv-link 进程装载）。
 *
 * 开启条件：game.enabled=true，且宿主有 SqlSessionFactory 与 Redis 连接。
 * 本类不跑迁移：db/game/*.sql 由人工按 docs/game/migration.md 执行（真库即线上库）。
 *
 * 属性（除 enabled 外全部可省；线上值以 vvv-link 的 bootstrap.yml game: 块为准）：
 *   game.enabled=true                  模块总开关
 *   game.ws.path=/api/game/ws          WebSocket 端点
 *   game.ws.allowed-origins=*          握手来源白名单（逗号分隔）
 *   game.zone=Asia/Shanghai            日切/赛季时区
 *   game.tickMs=200                    引擎心跳间隔
 *   game.commandRatePerMinute=1200     每连接命令令牌桶（约 20/s）
 *   game.matchBotFillMs=-1             -1 阶梯补位 / 0 关补位 / >0 统一补位
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

    // ---------------------------------------------------------------- 业务路由器

    /**
     * 匹配队列：默认 BOT_FILL_AFTER_MS 补位表（2/3 人桌 30s、4 人桌 45s），
     * enqueueWaitMs 用 TS 默认 60s。game.matchBotFillMs=0 可整体关补位。
     */
    @Bean
    public Matchmaking gameMatchmaking(@Value("${game.matchBotFillMs:-1}") long flatFillMs) {
        return flatFillMs == 0
            ? new Matchmaking()
            : Matchmaking.perCapacity(null, Matchmaking.BOT_FILL_AFTER_MS);
    }

    /**
     * GameHub（= GameCommandSink，WS 三件套的条件 Bean 就此满足）。
     * 事务接缝接宿主的 PlatformTransactionManager（MyBatis starter 必带）；
     * 跨季翻页接 GameSeasonService::sweep。房间号/随机源用默认（SecureRandom/Math::random）。
     */
    @Bean
    public GameHub gameHub(Clock clock, ZoneId zone,
                           GameProfileService profiles, GameWalletService wallet,
                           GameSettlementService settlement, Matchmaking matchmaking,
                           GameSeasonService seasons,
                           ObjectProvider<PlatformTransactionManager> txManagers) {
        GameHub.TxRunner tx = null;
        PlatformTransactionManager tm = txManagers.getIfAvailable();
        if (tm != null) {
            TransactionTemplate tt = new TransactionTemplate(tm);
            // TxRunner.run 是泛型方法，lambda 推不出函数描述符，只能匿名类。
            tx = new GameHub.TxRunner() {
                @Override public <T> T run(java.util.function.Supplier<T> work) {
                    return tt.execute(status -> work.get());
                }
            };
        }
        return new GameHub(new com.fasterxml.jackson.databind.ObjectMapper(), clock::millis, zone,
            profiles, wallet, settlement, matchmaking,
            null, null, seasons::sweep, tx);
    }

    /**
     * tick 驱动（TS main.ts 的 setInterval(tick, 200) 直译）：单线程调度器，
     * Hub 的全部业务语义因此保持单线程假设（类注释约定）。停机顺序：
     * 先 hub.shutdown()（退门票、关连接），再停调度器。
     */
    @Bean
    public GameTickDriver gameTickDriver(GameHub hub,
                                         @Value("${game.tickMs:200}") long tickMs) {
        return new GameTickDriver(hub, tickMs);
    }

    /** tick 循环宿主（生命周期归 Spring：容器关闭时优雅停机）。 */
    public static final class GameTickDriver implements DisposableBean {
        private final GameHub hub;
        private final ScheduledExecutorService executor =
            Executors.newSingleThreadScheduledExecutor(r -> {
                Thread t = new Thread(r, "game-tick");
                t.setDaemon(true);
                return t;
            });

        GameTickDriver(GameHub hub, long tickMs) {
            this.hub = hub;
            executor.scheduleWithFixedDelay(() -> {
                try {
                    hub.tick();
                } catch (RuntimeException ignored) {
                    // tick 里任何一桌/一次推送炸了都不能带走调度器（TS setInterval 同语义）；
                    // 真正的坏状态由审计 SQL 与健康检查兜。
                }
            }, tickMs, tickMs, TimeUnit.MILLISECONDS);
        }

        @Override
        public void destroy() {
            hub.shutdown();                      // 退款在关调度器之前：不再有并发 tick
            executor.shutdownNow();
        }
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
