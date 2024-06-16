package vpn.exception;

import com.timeline.vpn.Constant;

public class RegCodeException extends ApiException {
    /**
     *
     */
    private static final long serialVersionUID = 1L;

    public RegCodeException() {
        this(Constant.ResultMsg.RESULT_SYSTEMERROR);
    }

    public RegCodeException(String msg) {
        super(Constant.ResultErrno.ERRNO_DATA, msg);
    }

    public RegCodeException(int status, String msg) {
        super(status, msg);
    }
}
