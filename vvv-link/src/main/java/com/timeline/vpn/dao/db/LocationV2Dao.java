package vpn.dao.db;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.LocationPo;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * @author gqli
 * @date 2016年8月9日 下午12:23:47
 * @version V1.0
 */
public interface LocationV2Dao extends BaseDBDao<LocationPo> {
    public LocationPo get(@Param("id")int id);
    public LocationPo getByHostId(@Param("hostId")int hostId);
    public List<LocationPo> getAllInfoVpn();
    public List<LocationPo> getAllInfoVpnb();
    public List<LocationPo> getAllInfoVpnd();
    public List<LocationPo> getAllInfoVpnbTod();

}

