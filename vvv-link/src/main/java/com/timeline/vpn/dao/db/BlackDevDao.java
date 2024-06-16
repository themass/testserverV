package vpn.dao.db;

import com.timeline.vpn.model.po.BlackDevPo;
import org.apache.ibatis.annotations.Param;

/**
 * @author gqli
 * @date 2016年12月14日 下午12:32:29
 * @version V1.0
 */
public interface BlackDevDao {
    public BlackDevPo get(@Param("devId")String devId);
}

