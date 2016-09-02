package com.timeline.vpn.web.common.annotation;

import javax.servlet.http.HttpServletRequest;

import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

import com.timeline.vpn.Constant;
import com.timeline.vpn.exception.DataException;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.po.UserPo;

@Component
public class UserInfoResolver extends BaseResolver {
    @Override
    void resolve(BaseQuery baseQuery, HttpServletRequest webRequest, boolean required) {
        String token = webRequest.getHeader(Constant.HTTP_TOKEN_KEY);
        UserPo po = (UserPo)webRequest.getAttribute(Constant.HTTP_ATTR_TOKEN);
        if(required && (StringUtils.isEmpty(token)||po==null)){
            throw new DataException(Constant.ResultMsg.RESULT_TOKEN_EXPIRE);
        }
        baseQuery.setUser(po);
        baseQuery.setToken(token);
    }
}
