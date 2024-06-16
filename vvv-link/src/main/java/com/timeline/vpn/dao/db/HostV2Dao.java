package vpn.dao.db;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.HostPo;

import java.util.List;

/**
 * @author gqli
 * @date 2015年12月14日 下午7:13:46
 * @version V1.0
 */
public interface HostV2Dao extends BaseDBDao<HostPo> {
    public HostPo get(int id);
    public List<HostPo> getByLocation(int location);
}

