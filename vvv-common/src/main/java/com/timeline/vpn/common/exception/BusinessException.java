package com.timeline.vpn.common.exception;

import lombok.Data;
import lombok.EqualsAndHashCode;

@Data
@EqualsAndHashCode(callSuper = true)
public class BusinessException extends RuntimeException {

    /**
     * 异常对应的错误类型
     */
    private final ErrorType errorType;

    /**
     * 默认是系统异常
     */
    public BusinessException() {
        this.errorType = SystemErrorType.SYSTEM_ERROR;
    }

    public BusinessException(ErrorType errorType) {
        this.errorType = errorType;
    }

    public BusinessException(String message) {
        super(message);
        this.errorType = SystemErrorType.SYSTEM_ERROR;
    }

    public BusinessException(ErrorType errorType, String message) {
        super(message);
        this.errorType = errorType;
    }

    public BusinessException(ErrorType errorType, String message, Throwable cause) {
        super(message, cause);
        this.errorType = SystemErrorType.SYSTEM_ERROR;
    }

}
