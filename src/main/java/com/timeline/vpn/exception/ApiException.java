package com.timeline.vpn.exception;

public class ApiException extends RuntimeException {

    private static final long serialVersionUID = 1L;
    private final int status;

    public ApiException(int status, String msg) {
        super(msg);
        this.status = status;
    }

    public int getStatus() {
        return status;
    }


}
