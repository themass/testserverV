package com.timeline.vpn.service.impl;

import com.timeline.vpn.VoBuilder;
import com.timeline.vpn.dao.db.SettingCharacterDao;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.CharacterPo;
import com.timeline.vpn.model.vo.CharacterVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.Sessions;
import com.timeline.vpn.service.ChatService;
import com.timeline.vpn.service.impl.handle.chat.ChatContext;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class ChatServiceImpl implements ChatService {
//    public static String chatGptUrl = "http://book.ok123find.top/v1/chat/completions";
    //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
    //sk-4zWTqK981p5ee3GByGxPGNnTgltorSAUDQAXTa4qNe5kTjJn；

    @Autowired
    private SettingCharacterDao settingCharacterDao;
    @Autowired
    private ChatContext chatContext;

    @Override
    public Choice chatWithGpt(BaseQuery baseQuery, String content, String id, String charater) throws Exception {
        return chatContext.chatWithGpt(baseQuery, content, id, charater);
    }

    @Override
    public Choice transWord(BaseQuery baseQuery, String content, String id, String charater) throws Exception {
        return chatContext.transWord(baseQuery, content, id,charater);
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
        Sessions sessions2 = new Sessions();
        sessions2.setName("星座检测");
        sessions2.setType(0);
        sessions.add(sessions1);
        sessions.add(sessions2);
        infoListVo.setVoList(sessions);
        return infoListVo;
    }
}
