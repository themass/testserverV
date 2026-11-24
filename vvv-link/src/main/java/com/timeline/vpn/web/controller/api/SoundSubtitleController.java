package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.service.DataSoundSubtitleService;
import com.timeline.vpn.web.common.resolver.UserInfo;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 声音馆歌词（契约 sound-lyrics-contract §2）。挂在声音域下（/api/sound/subtitle），
 * 命名照视频域的 SubtitleController：items.json 列表（不含 content、无轨回空列表不是错误）、
 * item.json 单条取正文 {id,content,format,lang}。
 *
 * <p>MVP 一条目一轨（表上 UNIQUE(soundItemId)），列表不分页——不用 PageBaseForm，
 * 端上 soundSubtitles() 拿 voList 直接用（列表 VO 与视频字幕同一个 SubtitleVo）。
 *
 * <p>generate.json 必须登录（付费 API：不登录无法按用户定位滥用，照 PhotoSolveController
 * 的口径用 {@code @UserInfo(required = true)}），按条目去重在 service 里做。
 * 刻意不 extends BaseController：只依赖一个 Service，显式构造器注入，测试
 * standaloneSetup + 真实 UserInfoArgumentResolver 直接起（见 SoundSubtitleControllerTest）。
 *
 * @author gqli
 * @date 2026年11月24日
 * @version V1.0
 */
@RestController
@RequestMapping("/api/sound/subtitle")
public class SoundSubtitleController {
    private final DataSoundSubtitleService dataSoundSubtitleService;

    public SoundSubtitleController(DataSoundSubtitleService dataSoundSubtitleService) {
        this.dataSoundSubtitleService = dataSoundSubtitleService;
    }

    @RequestMapping(value = "/items.json", method = {RequestMethod.POST, RequestMethod.GET})
    public JsonResult items(@UserInfo BaseQuery baseQuery,
            @RequestParam(name = "soundItemId") long soundItemId) {
        return new JsonResult(dataSoundSubtitleService.getSoundSubtitleList(baseQuery, soundItemId));
    }

    @RequestMapping(value = "/item.json", method = {RequestMethod.POST, RequestMethod.GET})
    public JsonResult item(@UserInfo BaseQuery baseQuery, @RequestParam(name = "id") long id) {
        return new JsonResult(dataSoundSubtitleService.getSoundSubtitleContent(baseQuery, id));
    }

    @RequestMapping(value = "/generate.json", method = RequestMethod.POST)
    public JsonResult generate(@UserInfo(required = true) BaseQuery baseQuery,
            @RequestParam(name = "soundItemId") long soundItemId) {
        return new JsonResult(dataSoundSubtitleService.requestGeneration(baseQuery, soundItemId));
    }
}
