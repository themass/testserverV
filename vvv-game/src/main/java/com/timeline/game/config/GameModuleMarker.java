package com.timeline.game.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/** 装载标记：宿主 logs 里 grep "vvv-game module armed" 即可确认 game.enabled 生效。 */
public final class GameModuleMarker {
    private static final Logger LOGGER = LoggerFactory.getLogger(GameModuleMarker.class);

    public GameModuleMarker() {
        LOGGER.info("vvv-game module armed (persistence/realtime/ws beans land as later steps)");
    }
}
