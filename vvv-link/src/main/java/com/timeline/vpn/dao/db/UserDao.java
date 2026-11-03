package com.timeline.vpn.dao.db;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.UserPo;
import com.timeline.vpn.model.po.PasswordResetPo;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.Date;

/**
 * @author gqli
 * @date 2016年8月9日 上午11:22:16
 * @version V1.0
 */
@Mapper
public interface UserDao extends BaseDBDao<UserPo> {
    public UserPo getByEmail(String email);
    public void invalidateResetCodes(String name);
    public void insertResetCode(@Param(value = "name") String name,
                                @Param(value = "hash") String hash,
                                @Param(value = "expire") java.util.Date expire);
    public PasswordResetPo latestResetCode(String name);
    public void bumpResetAttempt(long id);
    public void markResetUsed(long id);
    public int updateVip(@Param(value = "name") String name, @Param(value = "level") int level,
                         @Param(value = "end") java.util.Date end);
    public int deductScore(@Param(value = "name") String name, @Param(value = "cost") long cost);
    public void updatePwdHash(@Param(value = "name") String name, @Param(value = "hash") String hash);
    public UserPo get(@Param(value = "name") String name, @Param(value = "pwd") String pwd);
    public UserPo updatePass(@Param(value = "name") String name, @Param(value = "pwd") String pwd);

    public UserPo exist(String name);

    public void score(@Param(value = "score") long score, @Param(value = "name") String name);
    public void updateEmail(@Param(value = "email") String email, @Param(value = "name") String name);
    
    public void initUserVip1(@Param(value = "time")Date time, @Param(value = "end")Date end);
    public void initUserVip2(@Param(value = "time")Date time, @Param(value = "end")Date end);
    
    public void updateLevel(UserPo po);
    public void updateLevelPaid(@Param(value = "start") Date start,@Param(value = "end") Date end);

}

