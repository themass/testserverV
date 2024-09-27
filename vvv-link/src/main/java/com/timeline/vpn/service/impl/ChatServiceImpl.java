package com.timeline.vpn.service.impl;

import com.timeline.vpn.VoBuilder;
import com.timeline.vpn.dao.db.SettingCharacterDao;
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
import com.timeline.vpn.web.controller.BaseController;
import com.volcengine.model.tls.LogGroup;
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
    public InfoListVo<CharacterVo> getCharacter(BaseQuery baseQuery) {
        List<CharacterPo> list = settingCharacterDao.getAll();
        return VoBuilder.buildListInfoVo(list, CharacterVo.class, null);
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
        sessions1.setId(1001l);

        Sessions sessions3 = new Sessions();
        sessions3.setName("红颜知己(Soulmate)");
        sessions3.setType(0);
        sessions3.setSetting("红颜知己");
        sessions1.setId(1002l);

        Sessions sessions4 = new Sessions();
        sessions4.setName("吵架小能手(DebateMaster)");
        sessions4.setType(0);
        sessions4.setSetting("吵架小能手");
        sessions1.setId(1003l);

        Sessions sessions5 = new Sessions();
        sessions5.setName("夸夸怪");
        sessions5.setType(0);
        sessions5.setSetting("夸夸怪");
        sessions1.setId(1004l);

        sessions.add(sessions1);
        sessions.add(sessions2);
        sessions.add(sessions3);
        sessions.add(sessions4);
        sessions.add(sessions5);
        infoListVo.setVoList(sessions);
        LOGGER.info("session list = "+ JsonUtil.writeValueAsString(infoListVo));
        return infoListVo;
    }
}
