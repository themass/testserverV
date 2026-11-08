package com.timeline.vpn.service.impl;

import com.timeline.vpn.VoBuilder;
import com.timeline.vpn.dao.db.SettingCharacterDao;
import com.timeline.vpn.common.exception.BusinessException;
import com.timeline.vpn.model.form.CharacterForm;
import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.CharacterPo;
import com.timeline.vpn.model.vo.CharacterVo;
import com.timeline.vpn.model.vo.ChatMessageVo;
import com.timeline.vpn.model.vo.ChatSessionVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.service.ChatHistoryService;
import com.timeline.vpn.service.ChatService;
import com.timeline.vpn.service.impl.handle.chat.ChatContext;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.List;

@Service
public class ChatServiceImpl implements ChatService {
protected static final Logger LOGGER = LoggerFactory.getLogger(ChatServiceImpl.class);

    @Autowired
    private SettingCharacterDao settingCharacterDao;
    @Autowired
    private ChatContext chatContext;
    @Autowired
    private ChatHistoryService chatHistoryService;

    /**
     * 非流式：先落用户消息（服务端历史），再调模型，成功后落助手回复。
     * 模型调用失败由 ChatContext 重试，用户消息只写一次。
     */
    @Override
    public Choice chatWithGpt(BaseQuery baseQuery, ChatContentForm chatContentForm) throws Exception {
        long userId = requireUserId(baseQuery);
        long userMessageId = chatHistoryService.beginTurn(userId, chatContentForm);
        Choice choice = chatContext.chatWithGpt(baseQuery, chatContentForm);
        String reply = choice == null || choice.getMessage() == null ? null : choice.getMessage().getContent();
        long assistantMessageId = chatHistoryService.saveAssistant(userId, chatContentForm.getSessionId(), reply);
        if (choice != null) {
            choice.setSessionId(chatContentForm.getSessionId());
            choice.setUserMessageId(userMessageId);
            choice.setAssistantMessageId(assistantMessageId);
        }
        return choice;
    }

    /** 流式：回合准备在请求线程完成；助手回复在流结束或被取消时保存（部分文本也会保存）。 */
    @Override
    public SseEmitter chatWithGptStream(BaseQuery baseQuery, ChatContentForm chatContentForm) {
        long userId = requireUserId(baseQuery);
        long userMessageId = chatHistoryService.beginTurn(userId, chatContentForm);
        long sessionId = chatContentForm.getSessionId();
        return chatContext.chatWithGptStream(baseQuery, chatContentForm, userMessageId,
                reply -> chatHistoryService.saveAssistant(userId, sessionId, reply));
    }

    @Override
    public InfoListVo<CharacterVo> getCharacter(BaseQuery baseQuery) {
        // 未登录时只看官方角色；getAll() 本身就是"所有行"，官方角色 ownerUserId 为 null，
        // 过滤交给调用方做更简单，不新开一条 SQL 分支
        Long userId = baseQuery.getUser() == null ? null : baseQuery.getUser().getId();
        List<CharacterPo> list = userId == null
                ? settingCharacterDao.getAll().stream().filter(po -> po.getOwnerUserId() == null).collect(java.util.stream.Collectors.toList())
                : settingCharacterDao.getVisibleTo(userId);
        return VoBuilder.buildListInfoVo(list, CharacterVo.class, (po, vo) ->
                vo.setMine(userId != null && userId.equals(po.getOwnerUserId())));
    }

    @Override
    public InfoListVo<ChatSessionVo> sessions(BaseQuery baseQuery) {
        return chatHistoryService.sessions(requireUserId(baseQuery));
    }

    @Override
    public ChatSessionVo createSession(BaseQuery baseQuery, String name, Integer characterId, String roleId) {
        return chatHistoryService.createSession(requireUserId(baseQuery), name, characterId, roleId);
    }

    @Override
    public ChatSessionVo renameSession(BaseQuery baseQuery, long sessionId, String name) {
        return chatHistoryService.renameSession(requireUserId(baseQuery), sessionId, name);
    }

    @Override
    public void deleteSession(BaseQuery baseQuery, long sessionId) {
        chatHistoryService.deleteSession(requireUserId(baseQuery), sessionId);
    }

    @Override
    public InfoListVo<ChatMessageVo> messages(BaseQuery baseQuery, long sessionId, Long beforeId, int limit) {
        return chatHistoryService.messages(requireUserId(baseQuery), sessionId, beforeId, limit);
    }

    @Override
    public void deleteMessage(BaseQuery baseQuery, long sessionId, long messageId) {
        chatHistoryService.deleteMessage(requireUserId(baseQuery), sessionId, messageId);
    }

    @Override
    public int clearMessages(BaseQuery baseQuery, long sessionId) {
        return chatHistoryService.clearMessages(requireUserId(baseQuery), sessionId);
    }

    @Override
    public ChatMessageVo editMessage(BaseQuery baseQuery, long sessionId, long messageId, String text) {
        return chatHistoryService.editMessage(requireUserId(baseQuery), sessionId, messageId, text);
    }

    @Override
    public CharacterVo createCharacter(BaseQuery baseQuery, CharacterForm form) {
        long userId = requireUserId(baseQuery);
        CharacterPo po = new CharacterPo();
        po.setTitle(form.getTitle());
        po.setContent(form.getContent());
        po.setUrl(form.getUrl());
        po.setExtra(form.getExtra());
        po.setOwnerUserId(userId);
        settingCharacterDao.insertCustom(po);
        return toVo(po, true);
    }

    @Override
    public CharacterVo updateCharacter(BaseQuery baseQuery, CharacterForm form) {
        long userId = requireUserId(baseQuery);
        if (form.getId() == null) {
            throw new BusinessException("缺少角色 id");
        }
        CharacterPo po = new CharacterPo();
        po.setId(form.getId());
        po.setTitle(form.getTitle());
        po.setContent(form.getContent());
        po.setUrl(form.getUrl());
        po.setExtra(form.getExtra());
        po.setOwnerUserId(userId);
        int affected = settingCharacterDao.updateCustom(po);
        if (affected == 0) {
            // 要么角色不存在，要么不是这个用户的——两种情况都不告诉调用方具体是哪种，
            // 避免被用来探测别人有没有这个角色 id
            throw new BusinessException("角色不存在或无权修改");
        }
        return toVo(po, true);
    }

    @Override
    public void deleteCharacter(BaseQuery baseQuery, int characterId) {
        long userId = requireUserId(baseQuery);
        int affected = settingCharacterDao.deleteCustom(characterId, userId);
        if (affected == 0) {
            throw new BusinessException("角色不存在或无权删除");
        }
    }

    private long requireUserId(BaseQuery baseQuery) {
        if (baseQuery.getUser() == null) {
            throw new BusinessException("请先登录");
        }
        return baseQuery.getUser().getId();
    }

    private CharacterVo toVo(CharacterPo po, boolean mine) {
        CharacterVo vo = new CharacterVo();
        vo.setId(po.getId());
        vo.setTitle(po.getTitle());
        vo.setContent(po.getContent());
        vo.setUrl(po.getUrl());
        vo.setExtra(po.getExtra());
        vo.setMine(mine);
        return vo;
    }
}
