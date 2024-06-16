package vpn.dao.db;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.DnsResverPo;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * @author gqli
 * @date 2015年12月14日 下午7:13:46
 * @version V1.0
 */
public interface DnsResverDao extends BaseDBDao<DnsResverPo> {
    public List<DnsResverPo> get(@Param(value = "domain")List<String> domain);
}

