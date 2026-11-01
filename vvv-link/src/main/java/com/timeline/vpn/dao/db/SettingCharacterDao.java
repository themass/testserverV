package com.timeline.vpn.dao.db;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.CharacterPo;
import org.apache.ibatis.annotations.Mapper;

import java.util.List;

/**
 * @author gqli
 * @date 2016年12月14日 下午12:32:29
 * @version V1.0
 */
@Mapper
public interface SettingCharacterDao extends BaseDBDao<CharacterPo> {
    public List<CharacterPo> getAll();

    /** 按 id 查单个角色，用于对话接口按 characterId 组装人设 prompt。 */
    public CharacterPo getById(int id);
}

