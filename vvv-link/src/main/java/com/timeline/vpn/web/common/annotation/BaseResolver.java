package vpn.web.common.annotation;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.web.common.DevAppContext;

import javax.servlet.ServletRequest;
import javax.servlet.http.HttpServletRequest;

/**
 *
 * @author gqli
 * @date 2015年8月18日 下午5:03:10
 * @version V1.0
 */
public abstract class BaseResolver implements ArgumentResolver<BaseQuery> {
    @Override
    public BaseQuery resolve(ServletRequest webRequest, boolean required) {
        BaseQuery query = new BaseQuery();
        HttpServletRequest req = (HttpServletRequest) webRequest;
        DevApp app = DevAppContext.get();
        query.setAppInfo(app);
        resolve(query, req, required);
        return query;
    }

    public abstract void resolve(BaseQuery baseQuery, HttpServletRequest webRequest, boolean required);
}
