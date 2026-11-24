package com.timeline.vpn.service.impl;

import com.timeline.vpn.VoBuilder;
import com.timeline.vpn.common.exception.BusinessException;
import com.timeline.vpn.dao.db.SoundChannelDao;
import com.timeline.vpn.dao.db.SoundSubtitleDao;
import com.timeline.vpn.model.chat.DeepgramListenResponse;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.SoundItems;
import com.timeline.vpn.model.po.SoundSubtitlePo;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.SoundSubtitleContentVo;
import com.timeline.vpn.model.vo.SoundSubtitleGenerateVo;
import com.timeline.vpn.model.vo.SubtitleVo;
import com.timeline.vpn.service.CacheService;
import com.timeline.vpn.service.DataSoundSubtitleService;
import com.timeline.vpn.service.impl.handle.asr.DeepgramAsrService;
import com.timeline.vpn.sound.SoundAudioUrl;
import com.timeline.vpn.sound.SrtFromSegments;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.Executor;

/**
 * 声音馆歌词（契约 sound-lyrics-contract §2）。读取侧照 DataSubtitleServiceImpl 模子：
 * 列表不 select content、正文单条取、未命中 BusinessException。
 *
 * <p>生成侧状态机：行不存在 → insertRunning（UNIQUE(soundItemId) 兜并发）→ 异步 generateTrack
 * → updateGenerated(ready) 或 updateGenStatus(failed)。按需去重两层：
 * ①行状态 running/ready 直接回状态不再起；②claim 用 redis lock 夹住 check-then-claim 的竞态窗口
 * （锁 TTL 60s 只管抢锁瞬间，生成跑多久靠 DB 里的 running）。
 *
 * <p>异步走注入的 soundAsrExecutor（不用 @Async：self-invocation 会绕开代理，job 复用同一条路径）。
 */
@Service
public class DataSoundSubtitleServiceImpl implements DataSoundSubtitleService {
    private static final Logger LOGGER = LoggerFactory.getLogger(DataSoundSubtitleServiceImpl.class);
    /** redis 抢锁键前缀；按条目隔离。 */
    private static final String CLAIM_LOCK_PREFIX = "soundSubtitle:claim:";
    static final String ENGINE = "deepgram:nova-2-general";

    private final SoundSubtitleDao soundSubtitleDao;
    private final SoundChannelDao soundChannelDao;
    private final CacheService cacheService;
    private final DeepgramAsrService deepgramAsrService;
    private final Executor soundAsrExecutor;

    public DataSoundSubtitleServiceImpl(SoundSubtitleDao soundSubtitleDao,
            SoundChannelDao soundChannelDao, CacheService cacheService,
            DeepgramAsrService deepgramAsrService,
            @Qualifier("soundAsrExecutor") Executor soundAsrExecutor) {
        this.soundSubtitleDao = soundSubtitleDao;
        this.soundChannelDao = soundChannelDao;
        this.cacheService = cacheService;
        this.deepgramAsrService = deepgramAsrService;
        this.soundAsrExecutor = soundAsrExecutor;
    }

    @Override
    public InfoListVo<SubtitleVo> getSoundSubtitleList(BaseQuery baseQuery, long soundItemId) {
        // MVP 一条目一轨，不分页（端上拿 voList 直接用；无轨=空列表，契约不是错误）
        List<SoundSubtitlePo> poList = soundSubtitleDao.getListBySoundItem(soundItemId);
        return VoBuilder.buildListInfoVo(poList, SubtitleVo.class,
                new VoBuilder.BuildAction<SoundSubtitlePo, SubtitleVo>() {
                    @Override
                    public void action(SoundSubtitlePo i, SubtitleVo t) {
                        // id/title/lang/format/size 由 BeanUtils 同名拷贝（size 是列表 SQL
                        // LENGTH(content) 的别名）；这里刻意什么都不做——加字段就等于把 content
                        // 带出去的风险。
                    }
                });
    }

    @Override
    public SoundSubtitleContentVo getSoundSubtitleContent(BaseQuery baseQuery, long id) {
        SoundSubtitlePo po = soundSubtitleDao.getContent(id);
        if (po == null) {
            throw new BusinessException("歌词不存在");
        }
        return VoBuilder.buildVo(po, SoundSubtitleContentVo.class, null);
    }

    @Override
    public SoundSubtitleGenerateVo requestGeneration(BaseQuery baseQuery, long soundItemId) {
        SoundSubtitleGenerateVo vo = new SoundSubtitleGenerateVo();
        SoundSubtitlePo row = soundSubtitleDao.getBySoundItem(soundItemId);
        if (row != null && ("running".equals(row.getGenStatus()) || "ready".equals(row.getGenStatus()))) {
            vo.setGenStatus(row.getGenStatus());
            vo.setStarted(false);
            return vo;
        }
        // ready 的条目重新生成走的是换文件后的重生成，Phase 2 不做——见 hand-over 笔记。
        long claim = cacheService.lock(CLAIM_LOCK_PREFIX + soundItemId);
        try {
            if (claim < 0) {                // 别人正在抢这条的生成：回显当前状态，不重复起
                SoundSubtitlePo again = soundSubtitleDao.getBySoundItem(soundItemId);
                vo.setGenStatus(again == null ? "running" : again.getGenStatus());
                vo.setStarted(false);
                return vo;
            }
            row = soundSubtitleDao.getBySoundItem(soundItemId);
            if (row != null && "running".equals(row.getGenStatus())) {
                // 锁拿到前一瞬别人已经抢了这条：不重复起（进程崩溃留下的僵尸 running 行
                // 需要人工改成 failed 才能重试——MVP 口径，见 hand-over 笔记）
                vo.setGenStatus("running");
                vo.setStarted(false);
                return vo;
            }
            if (row == null) {
                SoundItems item = soundChannelDao.getSoundItemById(soundItemId);
                if (item == null) {
                    throw new BusinessException("声音条目不存在");
                }
                row = newRunningRow(soundItemId, item.getName());
                try {
                    soundSubtitleDao.insertRunning(row);
                } catch (DuplicateKeyException e) {
                    // 并发请求已插行：谁先插谁生成
                    vo.setGenStatus("running");
                    vo.setStarted(false);
                    return vo;
                }
            } else {
                soundSubtitleDao.updateGenStatus(row.getId(), "running");
            }
        } finally {
            cacheService.unlock(CLAIM_LOCK_PREFIX + soundItemId);
        }
        final long rowId = row.getId();
        // generateTrack 自己吞异常并置 failed：这里的任务体不会抛，execute 足够（不需要 Future）
        soundAsrExecutor.execute(() -> generateTrack(rowId, soundItemId));
        vo.setGenStatus("running");
        vo.setStarted(true);
        return vo;
    }

    /** 真正的生成体（异步线程执行；失败置 genStatus=failed，不抛出）。 */
    void generateTrack(long subtitleRowId, long soundItemId) {
        try {
            SoundItems item = soundChannelDao.getSoundItemById(soundItemId);
            String audioUrl = SoundAudioUrl.resolve(item);
            if (audioUrl == null) {
                LOGGER.warn("sound subtitle {} item={} 没有可用音频地址", subtitleRowId, soundItemId);
                soundSubtitleDao.updateGenStatus(subtitleRowId, "failed");
                return;
            }
            DeepgramListenResponse resp = deepgramAsrService.recognizeUrl(audioUrl);
            List<SrtFromSegments.Segment> segments = toSegments(resp);
            String srt = SrtFromSegments.build(segments);
            if (srt.isEmpty()) {
                LOGGER.warn("sound subtitle {} item={} ASR 无有效分段", subtitleRowId, soundItemId);
                soundSubtitleDao.updateGenStatus(subtitleRowId, "failed");
                return;
            }
            soundSubtitleDao.updateGenerated(subtitleRowId, srt, SoundAudioUrl.sha256Hex(audioUrl),
                    ENGINE, "ready");
            LOGGER.info("sound subtitle {} item={} 生成完成 cues≈{}", subtitleRowId, soundItemId,
                    segments.size());
        } catch (Exception e) {
            LOGGER.error("sound subtitle " + subtitleRowId + " item=" + soundItemId + " 生成失败", e);
            try {
                soundSubtitleDao.updateGenStatus(subtitleRowId, "failed");
            } catch (Exception inner) {
                LOGGER.error("sound subtitle " + subtitleRowId + " 置 failed 也失败", inner);
            }
        }
    }

    private List<SrtFromSegments.Segment> toSegments(DeepgramListenResponse resp) {
        List<SrtFromSegments.Segment> segments = new ArrayList<>();
        if (resp == null || resp.getResults() == null || resp.getResults().getChannels() == null) {
            return segments;
        }
        for (DeepgramListenResponse.Channel ch : resp.getResults().getChannels()) {
            if (ch == null || ch.getAlternatives() == null || ch.getAlternatives().isEmpty()) {
                continue;
            }
            DeepgramListenResponse.Alternative alt = ch.getAlternatives().get(0);
            if (alt == null || alt.getSegments() == null) {
                continue;
            }
            for (DeepgramListenResponse.Segment s : alt.getSegments()) {
                if (s != null) {
                    segments.add(new SrtFromSegments.Segment(s.getStart(), s.getEnd(),
                            s.getTranscript()));
                }
            }
            break; // 单声道音频只看第一条 alternative
        }
        return segments;
    }

    private SoundSubtitlePo newRunningRow(long soundItemId, String name) {
        SoundSubtitlePo po = new SoundSubtitlePo();
        po.setSoundItemId(soundItemId);
        po.setTitle(name == null ? "" : name.length() > 200 ? name.substring(0, 200) : name);
        po.setLang("zh");
        po.setFormat("srt");
        po.setContent(""); // NOT NULL 列：running 期还没有正文
        po.setSourceFileHash(""); // ready 时才写指纹
        po.setGenStatus("running");
        po.setEngine("");
        po.setEnabled(1);
        po.setCreateTime(System.currentTimeMillis());
        return po;
    }
}
