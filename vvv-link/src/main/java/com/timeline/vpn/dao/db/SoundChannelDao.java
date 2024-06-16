package vpn.dao.db;

import com.timeline.vpn.dao.BaseDBDao;
import com.timeline.vpn.model.po.SoundChannel;
import com.timeline.vpn.model.po.SoundItems;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * @author gqli
 * @date 2015年12月14日 下午7:13:46
 * @version V1.0
 */
public interface SoundChannelDao extends BaseDBDao<SoundChannel> {
    public List<SoundItems> getByChannel(@Param("channel")String channel,@Param("keyword")String keyword);
    public List<SoundItems> getByChannelById(@Param("channel")String channel,@Param("keyword")String keyword);

}

