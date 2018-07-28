package com.timeline.vpn.dao.db;

import java.util.List;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.IWannaPo;

/**
 * @author gqli
 * @date 2015年12月14日 下午7:13:46
 * @version V1.0
 */
public interface IWannaDao extends BaseDBDao<IWannaPo> {
    public List<IWannaPo> getPage();

    public void like(IWannaPo po);

    public IWannaPo get(long id);
    
    public int insertFeed(IWannaPo po);
    public List<IWannaPo> getPageFeed();
    public void likeFeed(IWannaPo po);
    public IWannaPo getFeed(long id);
}

