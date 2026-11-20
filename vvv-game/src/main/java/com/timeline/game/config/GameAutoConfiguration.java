package com.timeline.game.config;

import org.apache.ibatis.session.SqlSessionFactory;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.data.redis.core.StringRedisTemplate;

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
}
