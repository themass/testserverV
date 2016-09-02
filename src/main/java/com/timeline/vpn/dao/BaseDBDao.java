package com.timeline.vpn.dao;
import java.util.List;

/**
 * @author gqli
 * @version V1.0
 * @date 2015年8月27日 上午10:35:30
 */
public interface BaseDBDao<T> {
    public List<T> getAll();

    public void insert(T t);
}