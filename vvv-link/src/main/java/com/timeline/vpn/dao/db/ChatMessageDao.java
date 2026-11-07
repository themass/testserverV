package com.timeline.vpn.dao.db;

import com.timeline.vpn.model.po.ChatMessagePo;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/** 对话消息（vpn.chat_message）。删除都是软删除。 */
@Mapper
public interface ChatMessageDao {

    int insert(ChatMessagePo po);

    /** 最近 limit 条未删除消息，按 id 倒序（调用方自己反转）。 */
    List<ChatMessagePo> recentDesc(@Param("sessionId") long sessionId, @Param("limit") int limit);

    /** 分页：id 小于 beforeId（为 null 则从最新开始）的 limit 条，按 id 倒序。 */
    List<ChatMessagePo> pageDesc(@Param("sessionId") long sessionId, @Param("beforeId") Long beforeId,
                                 @Param("limit") int limit);

    /** 本人会话里的一条未删除消息；不是本人的返回 null。 */
    ChatMessagePo getOwned(@Param("id") long id, @Param("sessionId") long sessionId, @Param("userId") long userId);

    /** 会话内同一个 clientMsgId 的未删除用户消息（幂等用）。 */
    ChatMessagePo findByClientMsgId(@Param("sessionId") long sessionId, @Param("clientMsgId") String clientMsgId);

    /** 会话里最后一条用户消息的 id；没有返回 null。 */
    Long lastUserId(@Param("sessionId") long sessionId);

    /** 软删除会话内 id 大于 afterId 的所有消息。 */
    int softDeleteAfter(@Param("sessionId") long sessionId, @Param("afterId") long afterId);

    int softDeleteOne(@Param("id") long id);

    int softDeleteAllInSession(@Param("sessionId") long sessionId);

    int updateContent(@Param("id") long id, @Param("content") String content);
}
