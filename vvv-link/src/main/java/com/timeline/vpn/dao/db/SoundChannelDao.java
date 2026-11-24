package com.timeline.vpn.dao.db;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.SoundChannel;
import com.timeline.vpn.model.po.SoundItems;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * @author gqli
 * @date 2015年12月14日 下午7:13:46
 * @version V1.0
 */
@Mapper
public interface SoundChannelDao extends BaseDBDao<SoundChannel> {
    public List<SoundItems> getByChannel(@Param("channel")String channel,@Param("keyword")String keyword);
    public List<SoundItems> getByChannelById(@Param("channel")String channel,@Param("keyword")String keyword);

    /** 单条声音条目（歌词生成要读 url/baseurl/file 拼音频地址）。 */
    public SoundItems getSoundItemById(@Param("id") long id);

}

