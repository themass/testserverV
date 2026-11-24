package com.timeline.vpn.model.vo;

import lombok.Data;

/**
 * 按需生成结果（POST /api/sound/subtitle/generate.json）。
 *
 * <p>契约 sound-lyrics-contract §2 Phase 2：端上 fire-and-forget，只看 errno；
 * started=true 表示这次请求真的拉起了生成，false 表示已在跑/已就绪/正在被别的请求占用。
 * genStatus 回显当前状态（pending/running/ready/failed），端上可用于下次进入前预判。
 */
@Data
public class SoundSubtitleGenerateVo {
    private String genStatus;
    private boolean started;
}
