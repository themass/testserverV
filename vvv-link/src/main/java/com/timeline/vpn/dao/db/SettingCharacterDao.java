package com.timeline.vpn.dao.db;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.CharacterPo;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

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

    /** 官方角色（ownerUserId 为 null）+ 指定用户自己上传的角色，供角色选择列表用。 */
    public List<CharacterPo> getVisibleTo(@Param("userId") long userId);

    /** 新增一个用户自定义角色；返回自增 id。 */
    public int insertCustom(CharacterPo po);

    /** 更新一个用户自定义角色；where 条件带 ownerUserId，防止越权改别人的角色。 */
    public int updateCustom(CharacterPo po);

    /** 删除一个用户自定义角色；where 条件带 ownerUserId，防止越权删别人的角色。 */
    public int deleteCustom(@Param("id") int id, @Param("ownerUserId") long ownerUserId);
}
