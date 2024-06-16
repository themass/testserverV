package com.timeline.vpn.dao.db;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.VideoChannelPo;
import com.timeline.vpn.model.po.VideoPo;
import com.timeline.vpn.model.po.VideoUserItemPo;
import com.timeline.vpn.model.po.VideoUserPo;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * @author gqli
 * @date 2016年12月14日 下午12:32:29
 * @version V1.0
 */
@Mapper
public interface VideoDao extends BaseDBDao<VideoPo> {
    public List<VideoPo> getPage();
    public VideoChannelPo getOneChannel(@Param("channel")String channel);
    public List<VideoChannelPo> getChannel(@Param("channelType")String channelType);
    public List<VideoPo> getChannelItems(@Param("channel")String channel,@Param("keyword")String keyword,@Param("channelType")String channelType, @Param("baseurl")String baseurl);
    public List<VideoUserPo> getUsers(@Param("channel")String channel);
    public VideoUserPo getUserByUserId(@Param("userId")String userId);
    public List<VideoUserItemPo> getUserItems(@Param("channel")String channel,@Param("userId")String userId,@Param("keyword")String keyword);
    
    public List<VideoChannelPo> getTvChannel(@Param("channel")String channel,@Param("keyword")String keyword);
    public List<VideoPo> getTvItem(@Param("channel")String channel);

    public VideoPo getOneItem(@Param("id")long id);
}

