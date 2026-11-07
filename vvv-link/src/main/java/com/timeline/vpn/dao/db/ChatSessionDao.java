package com.timeline.vpn.dao.db;

import com.timeline.vpn.model.po.ChatSessionPo;
import com.timeline.vpn.model.vo.ChatSessionVo;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/** 对话会话（vpn.chat_session）。所有查询都带 userId，保证用户隔离。 */
@Mapper
public interface ChatSessionDao {

    /** 插入会话，回填自增 id。 */
    int insert(ChatSessionPo po);

    /** 按 id 查本人未删除的会话；不是本人的返回 null。 */
    ChatSessionPo getOwned(@Param("id") long id, @Param("userId") long userId);

    /** 本人未删除的会话列表，按最近更新倒序，带最后一条消息和消息数。 */
    List<ChatSessionVo> listVo(@Param("userId") long userId);

    int rename(@Param("id") long id, @Param("userId") long userId, @Param("name") String name);

    /** 软删除本人的会话；返回影响行数。 */
    int softDelete(@Param("id") long id, @Param("userId") long userId);

    /** 刷新 updatedAt（有新消息时调用）。 */
    int touch(@Param("id") long id);

    /** 补齐人设：只填空字段，已有的不覆盖。 */
    int fillPersona(@Param("id") long id, @Param("characterId") Integer characterId, @Param("roleId") String roleId);
}
