package vpn.exception;

import com.timeline.vpn.Constant;

/**
*
 * @author gqli
 * @date 2015年7月27日 下午7:27:27
 * @version V1.0
 */
public class LoginException extends ApiException {

    /**
    
     */

    private static final long serialVersionUID = 1L;

    public LoginException() {
        this(Constant.ResultMsg.RESULT_PWD_ERROR);
    }

    public LoginException(String msg) {
        super(Constant.ResultErrno.ERRNO_PWD, msg);
    }

    public LoginException(int status, String msg) {
        super(status, msg);
    }
}

