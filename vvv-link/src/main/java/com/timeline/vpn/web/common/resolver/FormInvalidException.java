package com.timeline.vpn.web.common.resolver;
/**
 * @author gqli
 * @date 2016年9月12日 下午7:16:15
 * @version V1.0
 */
public class FormInvalidException  extends Exception{
   
    private static final long serialVersionUID = 1L;

    public FormInvalidException(String msg){
        super(msg);
    }
}

