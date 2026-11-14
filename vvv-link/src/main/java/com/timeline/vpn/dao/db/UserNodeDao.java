package com.timeline.vpn.dao.db;

import com.timeline.vpn.model.vo.UserNodeVo;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/** 用户自定义节点（表 vpn.user_node）。所有查询都带 user_name，保证用户隔离。 */
@Mapper
public interface UserNodeDao {

    List<UserNodeVo> listByUser(@Param("name") String name);

    /** 账号注销：删掉该用户保存在服务端的全部节点。 */
    int deleteByUser(@Param("name") String name);

    int insert(@Param("name") String name, @Param("node") UserNodeVo node);

    /** 更新本人的节点；id 属于别人时影响行数为 0。 */
    int update(@Param("name") String name, @Param("node") UserNodeVo node);

    /** 删除本人的节点；id 属于别人时影响行数为 0。 */
    int delete(@Param("name") String name, @Param("id") String id);
}
