package vpn.dao.db;

import com.timeline.vpn.model.po.RadCheck;
import com.timeline.vpn.model.po.RadUserGroup;
import org.apache.ibatis.annotations.Param;

/**
 * @author gqli
 * @date 2016年12月14日 下午12:12:26
 * @version V1.0
 */
public interface RadUserCheckDao {
    public void replaceUserGroup(RadUserGroup group);
    public void replaceUserPass(RadCheck check);
    public RadCheck getUserPass(@Param(value = "userName")String userName);
}

