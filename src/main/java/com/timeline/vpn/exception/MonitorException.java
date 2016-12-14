package com.timeline.vpn.exception;

import com.timeline.vpn.Constant;

public class MonitorException extends ApiException {
    /**
     *
     */
    private static final long serialVersionUID = 1L;

    public MonitorException() {
        this(Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR);
    }

    public MonitorException(String msg) {
        super(Constant.ResultErrno.ERRNO_DATA, msg);
    }

    public MonitorException(int status, String msg) {
        super(status, msg);
    }
}
