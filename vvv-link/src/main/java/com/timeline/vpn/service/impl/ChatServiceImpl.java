package com.timeline.vpn.service.impl;

import com.timeline.vpn.VoBuilder;
import com.timeline.vpn.dao.db.SettingCharacterDao;
import com.timeline.vpn.common.exception.BusinessException;
import com.timeline.vpn.model.form.CharacterForm;
import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.CharacterPo;
import com.timeline.vpn.model.vo.CharacterVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.Sessions;
import com.timeline.vpn.service.ChatService;
import com.timeline.vpn.service.impl.handle.chat.ChatContext;
import com.timeline.vpn.util.JsonUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class ChatServiceImpl implements ChatService {
//    public static String chatGptUrl = "http://book.ok123find.top/v1/chat/completions";
    //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
    //sk-4zWTqK981p5ee3GByGxPGNnTgltorSAUDQAXTa4qNe5kTjJn；
protected static final Logger LOGGER = LoggerFactory.getLogger(ChatServiceImpl.class);

    @Autowired
    private SettingCharacterDao settingCharacterDao;
    @Autowired
    private ChatContext chatContext;

    @Override
    public Choice chatWithGpt(BaseQuery baseQuery, ChatContentForm chatContentForm) throws Exception {
        Choice choice =  chatContext.chatWithGpt(baseQuery, chatContentForm);
        return choice;
    }

    @Override
    public org.springframework.web.servlet.mvc.method.annotation.SseEmitter chatWithGptStream(BaseQuery baseQuery, ChatContentForm chatContentForm) {
        return chatContext.chatWithGptStream(baseQuery, chatContentForm);
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

    @Override
    public InfoListVo<Sessions> sessions(BaseQuery baseQuery) {
        InfoListVo<Sessions> infoListVo= new InfoListVo<Sessions>();
        List<Sessions> sessions = new ArrayList<>();
        Sessions sessions1 = new Sessions();
        sessions1.setName("单词翻译(translation)");
        sessions1.setType(0);
        sessions1.setSetting("单词翻译");
        sessions1.setId(1000l);

        Sessions sessions2 = new Sessions();
        sessions2.setName("星座检测");
        sessions2.setType(0);
        sessions2.setSetting("星座检测");
        sessions2.setId(1001l);

        Sessions sessions3 = new Sessions();
        sessions3.setName("红颜知己(Soulmate)");
        sessions3.setType(0);
        sessions3.setSetting("红颜知己");
        sessions3.setId(1002l);

        Sessions sessions4 = new Sessions();
        sessions4.setName("吵架小能手(DebateMaster)");
        sessions4.setType(0);
        sessions4.setSetting("吵架小能手");
        sessions4.setId(1003l);

        Sessions sessions5 = new Sessions();
        sessions5.setName("夸夸怪");
        sessions5.setType(0);
        sessions5.setSetting("夸夸怪");
        sessions5.setId(1004l);

        Sessions sessions6 = new Sessions();
        sessions6.setName("文字冒险游戏");
        sessions6.setType(0);
        sessions6.setSetting("文字冒险游戏");
        sessions6.setId(1005l);

        Sessions sessions7 = new Sessions();
        sessions7.setName("讲故事");
        sessions7.setType(0);
        sessions7.setSetting("讲故事");
        sessions7.setId(1006l);

        sessions.add(sessions1);
        sessions.add(sessions2);
        sessions.add(sessions3);
        sessions.add(sessions4);
        sessions.add(sessions5);
        sessions.add(sessions6);
        sessions.add(sessions7);


        infoListVo.setVoList(sessions);
        LOGGER.info("session list = "+ JsonUtil.writeValueAsString(infoListVo));
        return infoListVo;
    }
}
