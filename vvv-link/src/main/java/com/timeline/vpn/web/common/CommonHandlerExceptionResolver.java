package vpn.web.common;

import com.timeline.vpn.Constant;
import com.timeline.vpn.exception.ApiException;
import com.timeline.vpn.exception.LoginException;
import com.timeline.vpn.exception.MonitorException;
import com.timeline.vpn.exception.TokenException;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.util.HttpCommonUtil;
import com.timeline.vpn.util.ResponseUtil;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.TypeMismatchException;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.support.DelegatingMessageSource;
import org.springframework.validation.BindException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.servlet.HandlerExceptionResolver;
import org.springframework.web.servlet.ModelAndView;
import org.springframework.web.util.UrlPathHelper;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.Locale;

public class CommonHandlerExceptionResolver implements HandlerExceptionResolver {

    private static final Logger LOGGER =
            LoggerFactory.getLogger(CommonHandlerExceptionResolver.class);

    private static final UrlPathHelper urlPathHelper = new UrlPathHelper();
    @Autowired
    private DelegatingMessageSource messagesource;
    @Override
    public ModelAndView resolveException(HttpServletRequest request, HttpServletResponse response,
            Object handler, Exception ex) {
        String ua = HttpCommonUtil.getUA(request.getHeader(Constant.HTTP_UA));
        String requestUrl = urlPathHelper.getRequestUri(request) + "?" + request.getQueryString()
                + "[" + ua + "]";
        JsonResult result = new JsonResult();
        if (ex instanceof MissingServletRequestParameterException) { // 缺少请求参数
            result.setErrno(Constant.ResultErrno.ERRNO_PARAM);
            result.setError(getMessage(Constant.ResultMsg.RESULT_PARAM_ERROR, request)
                    + ((MissingServletRequestParameterException) ex).getParameterName());
        } else if (ex instanceof HttpRequestMethodNotSupportedException) { // 请求方法错误
            result.setErrno(Constant.ResultErrno.ERRNO_PARAM);
            result.setError(ex.getMessage());
        } else if (ex instanceof TypeMismatchException) { // 请求参数类型错误
            result.setErrno(Constant.ResultErrno.ERRNO_PARAM);
            result.setError(getMessage(Constant.ResultMsg.RESULT_PARAM_ERROR, request));
        } else if (ex instanceof MonitorException) { // 请求参数类型错误
            result.setErrno(Constant.ResultErrno.ERRNO_PARAM);
            result.setError(ex.getMessage());
        }else if (ex instanceof TokenException) {
            try {
              ResponseUtil.writeResponse(response, ex.getMessage());
            } catch (IOException e) {
//              LOGGER.error("",e);
            }
        } else if (ex instanceof ApiException) {
            result.setErrno(((ApiException) ex).getStatus());
            result.setError(getMessage(ex.getMessage(), request));
        } else if (ex instanceof BindException) {
            result.setErrno(Constant.ResultErrno.ERRNO_PARAM);
            result.setError(getMessage(Constant.ResultMsg.RESULT_PARAM_ERROR, request));
        }else {
            result.setErrno(Constant.ResultErrno.ERRNO_SYSTEM);
            result.setError("System error，please try again");
//            LOGGER.error(requestUrl, ex);
        }
        if (ex instanceof ApiException) {
            if (ex instanceof LoginException) {
//                LOGGER.error("error url=" + requestUrl);
            }else {
                LOGGER.error("error url=" + requestUrl+"; error ="+ex.toString());
            }
        }else {
            LOGGER.error("error url=" + requestUrl+"; error ="+ex.toString());
        }
        LOGGER.error("",ex);
//        result.setError("系统正在进行升级，请稍等再用");
        // result.setData(new Object());
        return new ModelAndView("", JsonResult.MODEL_KEY, result);
    }

    private String getMessage(String key, HttpServletRequest request) {
        try {
            String msg = messagesource.getMessage(key, null, Locale.ENGLISH);
            if(StringUtils.isEmpty(msg)) {
                return key;
            }
            return msg;
        }catch (Exception e) {
            return key;
        }
    }

}
