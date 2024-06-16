package com.timeline.vpn.dao.db;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.TextChannelPo;
import com.timeline.vpn.model.po.TextItemPo;
import com.timeline.vpn.model.po.TextItemsPo;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * @author gqli
 * @date 2015年12月14日 下午7:13:46
 * @version V1.0
 */
@Mapper
public interface TextChannelDao extends BaseDBDao<TextChannelPo> {
    public List<TextItemsPo> getByChannel(@Param("channel")String channel, @Param("keyword")String keyword);
    public TextItemsPo getItemById(@Param("id")Integer id);
    public TextItemPo getFile(@Param("fileUrl")String fileUrl);
}

