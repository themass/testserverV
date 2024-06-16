package vpn.dao.db;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.RecommendPo;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * @author gqli
 * @date 2015年12月14日 下午7:13:46
 * @version V1.0
 */
public interface VpnRecommendDao extends BaseDBDao<RecommendPo> {
    public List<RecommendPo> getPage(@Param("type")int type);
    public List<RecommendPo> getVipPage();
    public List<RecommendPo> getCustomePage(@Param("name")String name);
    public List<RecommendPo> getCustomeAllPage();
    public void delCustome(@Param("id")Integer id);
    public void replaceCustome(RecommendPo po);
    public List<RecommendPo> getRecoPage();

    List<RecommendPo> getLocal();
}

