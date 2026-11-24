package com.timeline.vpn.service;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.SoundSubtitleContentVo;
import com.timeline.vpn.model.vo.SoundSubtitleGenerateVo;
import com.timeline.vpn.model.vo.SubtitleVo;

/**
 * 声音馆歌词（契约 sound-lyrics-contract §2）。列表不带正文，正文单条取——
 * 与视频字幕 DataSubtitleService 同构；列表 VO 直接复用 SubtitleVo（端上同一份镜像）。
 */
public interface DataSoundSubtitleService {

    /** 某声音条目的歌词列表（不含 content）。无轨回空列表，不是错误。 */
    InfoListVo<SubtitleVo> getSoundSubtitleList(BaseQuery baseQuery, long soundItemId);

    /** 歌词正文 {id,content,format,lang}；未命中抛 BusinessException。 */
    SoundSubtitleContentVo getSoundSubtitleContent(BaseQuery baseQuery, long id);

    /**
     * 按需生成（登录语义由 controller 的 @UserInfo(required=true) 把关，这里只管去重）：
     * 已在跑/已就绪直接回状态不重复起；failed/pending 重试。baseQuery 可为 null（补量 job）。
     */
    SoundSubtitleGenerateVo requestGeneration(BaseQuery baseQuery, long soundItemId);
}
