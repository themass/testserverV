package com.timeline.vpn.service;

import com.timeline.vpn.model.form.CharacterForm;
import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.CharacterVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.Sessions;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

/**
 * @author gqli
 * @date 2016年3月10日 下午4:44:14
 * @version V1.0
 */
public interface ChatService {
    
    public Choice chatWithGpt(BaseQuery baseQuery, ChatContentForm chatContentForm) throws Exception;

    public InfoListVo<CharacterVo> getCharacter(BaseQuery baseQuery);
    public InfoListVo<Sessions> sessions(BaseQuery baseQuery);

    /** 创建一个用户自定义角色，归属当前用户。 */
    public CharacterVo createCharacter(BaseQuery baseQuery, CharacterForm form);

    /** 更新自己的自定义角色；不是自己的角色会抛 BusinessException，不静默失败。 */
    public CharacterVo updateCharacter(BaseQuery baseQuery, CharacterForm form);

    /** 删除自己的自定义角色；不是自己的角色会抛 BusinessException。 */
    public void deleteCharacter(BaseQuery baseQuery, int characterId);

    public SseEmitter chatWithGptStream(BaseQuery baseQuery, ChatContentForm chatContentForm);


}

