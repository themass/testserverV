package vpn.dao.db;


import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.DomainPo;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * @author gqli
 * @date 2015年12月14日 下午7:13:46
 * @version V1.0
 */
public interface DomainDao extends BaseDBDao<DomainPo> {
    List<DomainPo> getList(@Param("channel")String channel);
}

