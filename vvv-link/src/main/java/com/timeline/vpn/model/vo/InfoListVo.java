package com.timeline.vpn.model.vo;

import com.google.common.collect.Lists;

import java.io.Serializable;
import java.util.List;

/**
 *
 * @author gqli
 * @date 2015年8月2日 下午6:28:07
 * @version V1.0
 */
public class InfoListVo<T> implements Serializable {
    /**
     * @Fields serialVersionUID :
     */
    private long total=0;
    private boolean hasMore=false;
    private int pageNum;
    private static final long serialVersionUID = 1L;
    private List<T> voList=Lists.newArrayList();

    public InfoListVo() {}

    public InfoListVo(List<T> voList) {
        this.voList = voList;
    }

    public List<T> getVoList() {
        return voList;
    }

    public void setVoList(List<T> voList) {
        this.voList = voList;
    }

    public long getTotal() {
        return total;
    }

    public void setTotal(long total) {
        this.total = total;
    }

    public boolean isHasMore() {
        return hasMore;
    }

    public void setHasMore(boolean hasMore) {
        this.hasMore = hasMore;
    }

    public int getPageNum() {
        return pageNum;
    }

    public void setPageNum(int pageNum) {
        this.pageNum = pageNum;
    }

    @Override
    public String toString() {
        return "InfoListVo [voList=" + voList + "]";
    }


}
