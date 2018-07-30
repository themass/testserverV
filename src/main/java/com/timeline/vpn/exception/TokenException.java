package com.timeline.vpn.exception;

import com.timeline.vpn.Constant;

public class TokenException extends ApiException {
    /**
     *
     */
    private static final long serialVersionUID = 1L;

    public TokenException() {
        this(Constant.ResultMsg.RESULT_SYSTEMERROR);
    }

    public TokenException(String msg) {
        super(Constant.ResultErrno.ERRNO_DATA, msg);
    }

    public TokenException(int status, String msg) {
        super(status, msg);
    }
}
