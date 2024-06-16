package com.timeline.vpn.exception;

import com.timeline.vpn.Constant;

/**
 *
 * @author gqli
 * @date 2015年7月27日 下午7:27:27
 * @version V1.0
 */
public class ParamException extends ApiException {

    /**
    
     */

    private static final long serialVersionUID = 1L;

    public ParamException() {
        this(Constant.ResultMsg.RESULT_DATA_ERROR);
    }

    public ParamException(String msg) {
        super(Constant.ResultErrno.ERRNO_PARAM, msg);
    }

    public ParamException(int status, String msg) {
        super(status, msg);
    }
}
