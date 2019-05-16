package com.timeline.vpn.dao.db;

import java.util.List;

import org.apache.ibatis.annotations.Param;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.IWannaPo;

/**
 * @author gqli
 * @date 2015年12月14日 下午7:13:46
 * @version V1.0
 */
public interface IWannaDao extends BaseDBDao<IWannaPo> {
    public List<IWannaPo> getPage(@Param("channel")String channel,@Param("name")String name);

    public void like(IWannaPo po);

    public IWannaPo get(long id);
    
    public int insertFeed(IWannaPo po);
    public List<IWannaPo> getPageFeed(@Param("channel")String channel,@Param("name")String name);
    public List<IWannaPo> getAllFeed();
    public void likeFeed(IWannaPo po);
    public IWannaPo getFeed(long id);
}

