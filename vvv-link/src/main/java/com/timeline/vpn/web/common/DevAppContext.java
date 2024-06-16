package com.timeline.vpn.web.common;

import com.timeline.vpn.model.param.DevApp;
import org.springframework.core.NamedThreadLocal;

/**
 * @author gqli
 * @date 2016年12月12日 下午7:02:03
 * @version V1.0
 */
public class DevAppContext {
    private static NamedThreadLocal<DevApp> devapp =
            new NamedThreadLocal<DevApp>("devapp");
    public static void set(DevApp app){
        devapp.set(app);
    }
    public static DevApp get(){
        return devapp.get();
    }
}

