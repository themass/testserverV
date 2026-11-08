package com.timeline.vpn.service.impl;

import com.timeline.vpn.Constant;
import com.timeline.vpn.common.exception.BusinessException;
import com.timeline.vpn.exception.ApiException;
import com.timeline.vpn.common.utils.JacksonJsonUtil;
import com.timeline.vpn.dao.db.ChatMessageDao;
import com.timeline.vpn.dao.db.ChatSessionDao;
import com.timeline.vpn.model.chat.ChatMsg;
import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.po.ChatMessagePo;
import com.timeline.vpn.model.po.ChatSessionPo;
import com.timeline.vpn.model.vo.ChatMessageVo;
import com.timeline.vpn.model.vo.ChatSessionVo;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.service.ChatHistoryService;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Redis 缓存结构：key = chat:{userId}:{sessionId}，list 里是 ChatMsg 的 JSON，最旧在左。
 * - 读：命中则 LRANGE 并刷新 TTL；未命中从 MySQL 取最近 CACHE_SIZE 条回填。
 * - 写：只有键已存在才追加（LTRIM 限长并刷新 TTL），键不存在就不建，留给下次读时整段回填，避免半截缓存。
 * - 失效：删消息、改消息、重新生成、删会话时直接 DEL。
 * 所有 Redis 异常都降级为直接读库，不影响正确性。
 */
@Service
public class ChatHistoryServiceImpl implements ChatHistoryService {
    private static final Logger LOGGER = LoggerFactory.getLogger(ChatHistoryServiceImpl.class);

    static final int CACHE_SIZE = 60;
    static final int PROMPT_WINDOW = 30;
    static final int MAX_PAGE = 200;
    static final int NAME_MAX = 20;
    static final String DEFAULT_NAME = "新对话";
    static final Duration TTL = Duration.ofDays(7);
    private static final String KEY_PREFIX = "chat:";

    @Autowired
    private ChatSessionDao sessionDao;
    @Autowired
    private ChatMessageDao messageDao;
    @Autowired
    private StringRedisTemplate redis;

    // ------------------------------------------------------------------
    // 对话回合
    // ------------------------------------------------------------------

    @Override
    public long beginTurn(long userId, ChatContentForm form) {
        boolean regenerate = form.isRegenerate();
        String text = form.getText() == null ? null : form.getText().trim();
        if (!regenerate && StringUtils.isBlank(text)) {
            throw new BusinessException("消息不能为空");
        }

        ChatSessionPo session;
        if (form.getSessionId() > 0) {
            session = requireOwned(userId, form.getSessionId());
        } else {
            session = createSessionPo(userId, nameFrom(text), form.getCharacterId(), form.getRoleId());
        }
        long sessionId = session.getId();
        form.setSessionId(sessionId);

        // 人设以会话为准：请求没带的就用会话里存的；请求带了而会话里是空的，补进会话
        if (form.getCharacterId() == null || form.getCharacterId() <= 0) {
            form.setCharacterId(session.getCharacterId());
        }
        if (StringUtils.isBlank(form.getRoleId())) {
            form.setRoleId(session.getRoleId());
        }
        boolean hasCharacter = form.getCharacterId() != null && form.getCharacterId() > 0;
        boolean hasRole = StringUtils.isNotBlank(form.getRoleId());
        if (hasCharacter || hasRole) {
            sessionDao.fillPersona(sessionId, hasCharacter ? form.getCharacterId() : null,
                    hasRole ? form.getRoleId() : null);
        }

        if (regenerate) {
            Long lastUser = messageDao.lastUserId(sessionId);
            if (lastUser != null) {
                messageDao.softDeleteAfter(sessionId, lastUser);
                invalidate(userId, sessionId);
                sessionDao.touch(sessionId);
                return lastUser;
            }
            return 0L;
        }
        return appendUser(userId, session, text, form.getId());
    }

    private long appendUser(long userId, ChatSessionPo session, String text, String clientMsgId) {
        long sessionId = session.getId();
        String msgId = StringUtils.trimToNull(clientMsgId);
        if (msgId != null && msgId.length() > 64) {
            msgId = msgId.substring(0, 64);
        }
        if (msgId != null) {
            // 同一个客户端消息 id 重发：不重复插入，把它之后的回复丢掉，等下面重新回答
            ChatMessagePo dup = messageDao.findByClientMsgId(sessionId, msgId);
            if (dup != null) {
                messageDao.softDeleteAfter(sessionId, dup.getId());
                invalidate(userId, sessionId);
                sessionDao.touch(sessionId);
                return dup.getId();
            }
        }
        ChatMessagePo po = new ChatMessagePo();
        po.setSessionId(sessionId);
        po.setUserId(userId);
        po.setRole("user");
        po.setContent(text);
        po.setType(0);
        po.setClientMsgId(msgId);
        messageDao.insert(po);
        sessionDao.touch(sessionId);
        if (DEFAULT_NAME.equals(session.getName())) {
            // 第一轮对话：会话名取消息前 NAME_MAX 字
            sessionDao.rename(sessionId, userId, nameFrom(text));
        }
        appendCache(userId, sessionId, "user", text);
        return po.getId();
    }

    @Override
    public long saveAssistant(long userId, long sessionId, String text) {
        if (StringUtils.isBlank(text)) {
            return 0L;
        }
        ChatMessagePo po = new ChatMessagePo();
        po.setSessionId(sessionId);
        po.setUserId(userId);
        po.setRole("assistant");
        po.setContent(text);
        po.setType(0);
        messageDao.insert(po);
        sessionDao.touch(sessionId);
        appendCache(userId, sessionId, "assistant", text);
        return po.getId();
    }

    @Override
    public String promptHistory(long userId, long sessionId) {
        List<ChatMsg> msgs = readWindow(userId, sessionId);
        int from = Math.max(0, msgs.size() - PROMPT_WINDOW);
        return msgs.subList(from, msgs.size()).stream()
                .map(m -> "[" + m.getRole() + "]" + m.getContent())
                .collect(Collectors.joining("\n"));
    }

    // ------------------------------------------------------------------
    // 会话
    // ------------------------------------------------------------------

    @Override
    public InfoListVo<ChatSessionVo> sessions(long userId) {
        List<ChatSessionVo> list = sessionDao.listVo(userId);
        if (list.isEmpty()) {
            createSessionPo(userId, DEFAULT_NAME, null, null);
            list = sessionDao.listVo(userId);
        }
        InfoListVo<ChatSessionVo> vo = new InfoListVo<>();
        vo.setVoList(list);
        vo.setTotal(list.size());
        return vo;
    }

    @Override
    public ChatSessionVo createSession(long userId, String name, Integer characterId, String roleId) {
        ChatSessionPo po = createSessionPo(userId, StringUtils.isBlank(name) ? DEFAULT_NAME : nameFrom(name),
                characterId, roleId);
        return toSessionVo(po);
    }

    @Override
    public ChatSessionVo renameSession(long userId, long sessionId, String name) {
        if (StringUtils.isBlank(name)) {
            throw new BusinessException("会话名不能为空");
        }
        int affected = sessionDao.rename(sessionId, userId, nameFrom(name));
        if (affected == 0) {
            throw new BusinessException("会话不存在或无权修改");
        }
        return toSessionVo(requireOwned(userId, sessionId));
    }

    @Override
    @Transactional
    public void deleteSession(long userId, long sessionId) {
        int affected = sessionDao.softDelete(sessionId, userId);
        if (affected == 0) {
            throw new BusinessException("会话不存在或无权删除");
        }
        messageDao.softDeleteAllInSession(sessionId);
        invalidate(userId, sessionId);
    }

    // ------------------------------------------------------------------
    // 消息
    // ------------------------------------------------------------------

    @Override
    public InfoListVo<ChatMessageVo> messages(long userId, long sessionId, Long beforeId, int limit) {
        requireOwned(userId, sessionId);
        int size = Math.max(1, Math.min(limit, MAX_PAGE));
        List<ChatMessagePo> rows = new ArrayList<>(messageDao.pageDesc(sessionId, beforeId, size + 1));
        boolean hasMore = rows.size() > size;
        if (hasMore) {
            rows = rows.subList(0, size);
        }
        Collections.reverse(rows);
        InfoListVo<ChatMessageVo> vo = new InfoListVo<>();
        vo.setVoList(rows.stream().map(this::toMessageVo).collect(Collectors.toList()));
        vo.setHasMore(hasMore);
        return vo;
    }

    @Override
    public void deleteMessage(long userId, long sessionId, long messageId) {
        requireOwned(userId, sessionId);
        ChatMessagePo po = messageDao.findById(messageId);
        // 不存在、或属于别的会话/用户：明确的错误码（客户端据此提示，而不是 System error）
        if (po == null || po.getSessionId() != sessionId || po.getUserId() != userId) {
            throw new ApiException(Constant.ResultErrno.ERRNO_MESSAGE_NOT_FOUND, "消息不存在或无权删除");
        }
        // 已经删除：幂等成功，重复请求不报错
        if (po.getDeleted() != 0) {
            return;
        }
        messageDao.softDeleteOne(messageId);
        invalidate(userId, sessionId);
    }

    @Override
    @Transactional
    public int clearMessages(long userId, long sessionId) {
        requireOwned(userId, sessionId);
        int deleted = messageDao.softDeleteAllInSession(sessionId);
        sessionDao.touch(sessionId);
        invalidate(userId, sessionId);
        return deleted;
    }

    @Override
    @Transactional
    public ChatMessageVo editMessage(long userId, long sessionId, long messageId, String text) {
        requireOwned(userId, sessionId);
        if (StringUtils.isBlank(text)) {
            throw new BusinessException("消息不能为空");
        }
        ChatMessagePo po = messageDao.getOwned(messageId, sessionId, userId);
        if (po == null) {
            throw new BusinessException("消息不存在");
        }
        if (!"user".equals(po.getRole())) {
            throw new BusinessException("只能编辑用户消息");
        }
        messageDao.updateContent(messageId, text);
        messageDao.softDeleteAfter(sessionId, messageId);
        sessionDao.touch(sessionId);
        invalidate(userId, sessionId);
        po.setContent(text);
        return toMessageVo(po);
    }

    // ------------------------------------------------------------------
    // 内部工具
    // ------------------------------------------------------------------

    private ChatSessionPo requireOwned(long userId, long sessionId) {
        ChatSessionPo po = sessionDao.getOwned(sessionId, userId);
        if (po == null) {
            throw new BusinessException("会话不存在或无权访问");
        }
        return po;
    }

    private ChatSessionPo createSessionPo(long userId, String name, Integer characterId, String roleId) {
        ChatSessionPo po = new ChatSessionPo();
        po.setUserId(userId);
        po.setName(name);
        po.setCharacterId(characterId != null && characterId > 0 ? characterId : null);
        po.setRoleId(StringUtils.isBlank(roleId) ? null : roleId);
        sessionDao.insert(po);
        return po;
    }

    static String nameFrom(String text) {
        String t = StringUtils.trimToEmpty(text);
        if (t.isEmpty()) {
            return DEFAULT_NAME;
        }
        return t.length() > NAME_MAX ? t.substring(0, NAME_MAX) : t;
    }

    private ChatSessionVo toSessionVo(ChatSessionPo po) {
        ChatSessionVo vo = new ChatSessionVo();
        vo.setId(po.getId());
        vo.setName(po.getName());
        vo.setCharacterId(po.getCharacterId());
        vo.setRoleId(po.getRoleId());
        vo.setCreatedAt(po.getCreatedAt() == null ? 0 : po.getCreatedAt().getTime());
        vo.setUpdatedAt(po.getUpdatedAt() == null ? 0 : po.getUpdatedAt().getTime());
        return vo;
    }

    private ChatMessageVo toMessageVo(ChatMessagePo po) {
        ChatMessageVo vo = new ChatMessageVo();
        vo.setId(po.getId());
        vo.setSessionId(po.getSessionId());
        vo.setRole(po.getRole());
        vo.setContent(po.getContent());
        vo.setType(po.getType());
        vo.setClientMsgId(po.getClientMsgId());
        vo.setCreatedAt(po.getCreatedAt() == null ? 0 : po.getCreatedAt().getTime());
        return vo;
    }

    private static String key(long userId, long sessionId) {
        return KEY_PREFIX + userId + ":" + sessionId;
    }

    /** 读取最近 CACHE_SIZE 条：先读 Redis，未命中回填。 */
    private List<ChatMsg> readWindow(long userId, long sessionId) {
        String key = key(userId, sessionId);
        try {
            List<String> raw = redis.opsForList().range(key, 0, -1);
            if (raw != null && !raw.isEmpty()) {
                redis.expire(key, TTL);
                return raw.stream()
                        .map(s -> JacksonJsonUtil.readValue(s, ChatMsg.class))
                        .filter(m -> m != null)
                        .collect(Collectors.toList());
            }
        } catch (Exception e) {
            LOGGER.warn("读取对话缓存失败，降级读库 key=" + key, e);
        }
        List<ChatMessagePo> rows = new ArrayList<>(messageDao.recentDesc(sessionId, CACHE_SIZE));
        Collections.reverse(rows);
        List<ChatMsg> msgs = rows.stream()
                .map(p -> new ChatMsg(p.getRole(), p.getContent()))
                .collect(Collectors.toList());
        fillCache(key, msgs);
        return msgs;
    }

    private void fillCache(String key, List<ChatMsg> msgs) {
        if (msgs.isEmpty()) {
            return;
        }
        try {
            redis.delete(key);
            List<String> items = msgs.stream().map(JacksonJsonUtil::toJsonStr).collect(Collectors.toList());
            redis.opsForList().rightPushAll(key, items);
            redis.expire(key, TTL);
        } catch (Exception e) {
            LOGGER.warn("回填对话缓存失败 key=" + key, e);
        }
    }

    private void appendCache(long userId, long sessionId, String role, String content) {
        String key = key(userId, sessionId);
        try {
            if (Boolean.TRUE.equals(redis.hasKey(key))) {
                redis.opsForList().rightPush(key, JacksonJsonUtil.toJsonStr(new ChatMsg(role, content)));
                redis.opsForList().trim(key, -CACHE_SIZE, -1);
                redis.expire(key, TTL);
            }
        } catch (Exception e) {
            LOGGER.warn("追加对话缓存失败 key=" + key, e);
        }
    }

    private void invalidate(long userId, long sessionId) {
        try {
            redis.delete(key(userId, sessionId));
        } catch (Exception e) {
            LOGGER.warn("清除对话缓存失败 sessionId=" + sessionId, e);
        }
    }
}
