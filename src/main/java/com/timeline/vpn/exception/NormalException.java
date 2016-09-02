package com.timeline.vpn.exception;

import com.timeline.vpn.Constant;

public class NormalException extends ApiException {
    /**
     *
     */
    private static final long serialVersionUID = 1L;

    public NormalException() {
        this(Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR);
    }

    public NormalException(String msg) {
        super(Constant.ResultErrno.ERRNO_DATA, msg);
    }

    public NormalException(int status, String msg) {
        super(status, msg);
    }
}
