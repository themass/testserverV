package vpn.dao.db;

import com.timeline.vpn.model.po.Radacct;
import com.timeline.vpn.model.po.RadacctState;
import org.apache.ibatis.annotations.Param;

import java.util.Date;
import java.util.List;

/**
 * @author gqli
 * @date 2016年12月14日 下午12:12:26
 * @version V1.0
 */
public interface RadacctDao {
    public RadacctState dateState(@Param("names")List<String> name);
    public List<Radacct> selectIpLocal();
    public void updateIpLocal(@Param("list")List<Radacct>list);
    public int deleteHistoryAcce(@Param("time")Date time);
    public int deleteHistoryAuth(@Param("time")Date time);
   
}

