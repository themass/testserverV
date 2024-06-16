package vpn.web.common.resolver;

import com.timeline.vpn.Constant;
import com.timeline.vpn.exception.LoginException;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.UserPo;
import com.timeline.vpn.web.common.DevAppContext;
import com.timeline.vpn.web.common.annotation.BaseResolver;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import javax.servlet.http.HttpServletRequest;

@Component
public class UserInfoResolver extends BaseResolver {
    @Override
    public void resolve(BaseQuery baseQuery, HttpServletRequest webRequest, boolean required) {
        String token = webRequest.getHeader(DevAppContext.get().getTokenHeader());
        UserPo po = (UserPo) webRequest.getAttribute(Constant.HTTP_ATTR_TOKEN);
        if (required && (StringUtils.isEmpty(token) || po == null)) {
            throw new LoginException(Constant.ResultMsg.RESULT_TOKEN_EXPIRE);
        }
        baseQuery.setUser(po);
        baseQuery.setToken(token);
    }
}
