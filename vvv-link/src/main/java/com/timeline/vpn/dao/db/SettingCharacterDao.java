package vpn.dao.db;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.CharacterPo;

import java.util.List;

/**
 * @author gqli
 * @date 2016年12月14日 下午12:32:29
 * @version V1.0
 */
public interface SettingCharacterDao extends BaseDBDao<CharacterPo> {
    public List<CharacterPo> getAll();
}

