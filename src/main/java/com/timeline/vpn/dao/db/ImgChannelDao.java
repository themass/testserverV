package com.timeline.vpn.dao.db;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.ImgChannelPo;
import com.timeline.vpn.model.po.ImgItemsItemPo;
import com.timeline.vpn.model.po.ImgItemsPo;

/**
 * @author gqli
 * @date 2015年12月14日 下午7:13:46
 * @version V1.0
 */
public interface ImgChannelDao extends BaseDBDao<ImgChannelPo> {
    public List<ImgChannelPo> getChannel(@Param("channel")String channel);
    public List<ImgItemsPo> getByChannel(@Param("channel")String channel,@Param("keyword")String keyword);
    public ImgItemsPo getByUrl(@Param("url")String url);
    public List<ImgItemsItemPo> getItem(@Param("itemUrl")String itemUrl);
}

