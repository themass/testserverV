package com.timeline.vpn.exception;

import com.timeline.vpn.Constant;

/**
 *
 * @author gqli
 * @date 2015年7月27日 下午7:27:27
 * @version V1.0
 */
public class DataException extends ApiException {

    /**
    
     */

    private static final long serialVersionUID = 1L;

    public DataException() {
        this(Constant.ResultMsg.RESULT_DATA_ERROR);
    }

    public DataException(String msg) {
        super(Constant.ResultErrno.ERRNO_DATA, msg);
    }

    public DataException(int status, String msg) {
        super(status, msg);
    }
}
