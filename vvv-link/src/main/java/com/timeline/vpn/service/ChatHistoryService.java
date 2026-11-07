package com.timeline.vpn.service;

import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.vo.ChatMessageVo;
import com.timeline.vpn.model.vo.ChatSessionVo;
import com.timeline.vpn.model.vo.InfoListVo;

/**
 * 对话历史的唯一权威来源（MySQL），Redis 只是每个会话最近 N 条的缓存。
 * 所有方法都以 userId 做归属校验，不属于该用户的会话/消息一律报错。
 */
public interface ChatHistoryService {

    /**
     * 一轮对话开始前调用：解析/新建会话、补齐人设、写入用户消息（或重新生成时删掉旧回复）。
     * 调用后 form 的 sessionId / characterId / roleId 会被回填为服务端的值。
     */
    long beginTurn(long userId, ChatContentForm form);

    /** 一轮对话结束后保存助手回复；空白内容不落库。 */
    long saveAssistant(long userId, long sessionId, String text);

    /** 提示词里的历史文本（[user]...\n[assistant]...），取最近若干条。 */
    String promptHistory(long userId, long sessionId);

    InfoListVo<ChatSessionVo> sessions(long userId);

    ChatSessionVo createSession(long userId, String name, Integer characterId, String roleId);

    ChatSessionVo renameSession(long userId, long sessionId, String name);

    void deleteSession(long userId, long sessionId);

    InfoListVo<ChatMessageVo> messages(long userId, long sessionId, Long beforeId, int limit);

    void deleteMessage(long userId, long sessionId, long messageId);

    /** 改一条用户消息，并删掉它之后的所有消息（回复需要重新生成）。 */
    ChatMessageVo editMessage(long userId, long sessionId, long messageId, String text);
}
