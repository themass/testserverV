package com.timeline.vpn.service.job.reload;

import com.timeline.vpn.dao.db.LockJobDao;
import com.timeline.vpn.dao.db.SoundSubtitleDao;
import com.timeline.vpn.model.po.LockJobPo;
import com.timeline.vpn.model.po.SoundItems;
import com.timeline.vpn.service.DataSoundSubtitleService;
import com.timeline.vpn.service.job.ReloadJob;
import com.timeline.vpn.util.DateTimeUtils;
import com.timeline.vpn.util.IpLocalUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;

/**
 * 声音馆歌词补量（契约 sound-lyrics-contract §2 Phase 2「补量」）。
 *
 * <p>主路是端上按需触发（SoundSubtitleController.generate.json），本 job 只兜没人点过的条目：
 * 每轮取 N 条还没有任何歌词轨的条目，逐条走与按需完全相同的生成路径。
 *
 * <p>跨实例互斥照仓内先例（Score3Calculation/HostIpMonitor）：往 vpn.lock_job 插一行
 * 「jobName + 本轮时间」，插入成功的那台才干活——本库没有分布式锁表以外的机制，
 * jobName+时间粒度到分钟，同一分钟只有一个实例进得来。
 *
 * <p>串行提交（不在这里起线程）：池只有 3 线程且 Deepgram 有并发配额，job 逐条 submit
 * 就够了，跑不完的下一轮接着补。
 */
@Component
public class SoundSubtitleBackfill extends ReloadJob {
    private static final Logger LOGGER = LoggerFactory.getLogger(SoundSubtitleBackfill.class);
    private static final String JOB_NAME = "SoundSubtitleBackfill";
    /** 每轮补几条：Deepgram 按分钟计费但更怕并发打爆，小步快跑。 */
    private static final int BATCH = 5;

    @Autowired
    private LockJobDao lockJobDao;
    @Autowired
    private SoundSubtitleDao soundSubtitleDao;
    @Autowired
    private DataSoundSubtitleService dataSoundSubtitleService;

    @Override
    @Transactional
    public void reload() {
        LockJobPo lock = new LockJobPo();
        lock.setJobName(JOB_NAME);
        // 粒度到 10 分钟：cron 每 30 分钟一轮，同一轮多实例只有一次能插进去
        String time = DateTimeUtils.formatDate(DateTimeUtils.YYYY_MM_DDHH_MM, new Date());
        lock.setJobTime(time.substring(0, time.length() - 1) + "0");
        lock.setIp(IpLocalUtil.getHostIp());
        try {
            if (lockJobDao.insert(lock) <= 0) {
                return;
            }
        } catch (Exception e) {
            // 唯一键冲突 = 别的实例本轮已经接过活，静默退出（照 HostIpMonitor 的处理）
            LOGGER.debug("{} 本轮已被其它实例占用", JOB_NAME);
            return;
        }

        List<SoundItems> items = soundSubtitleDao.listItemsWithoutTrack(BATCH);
        if (items == null || items.isEmpty()) {
            LOGGER.info("{} 没有待补条目", JOB_NAME);
            return;
        }
        LOGGER.info("{} 本轮补 {} 条", JOB_NAME, items.size());
        for (SoundItems item : items) {
            try {
                // 复用按需路径：插 running 行 + submit 生成，状态机同一套
                dataSoundSubtitleService.requestGeneration(null, item.getId());
            } catch (Exception e) {
                LOGGER.error(JOB_NAME + " 补条目 " + item.getId() + " 失败", e);
            }
        }
    }
}
