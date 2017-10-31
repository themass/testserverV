package com.timeline.vpn.dao.db;

import java.util.List;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.VideoPo;

/**
 * @author gqli
 * @date 2016年12月14日 下午12:32:29
 * @version V1.0
 */
public interface VideoDao extends BaseDBDao<VideoPo> {
    public List<VideoPo> getPage();
}

