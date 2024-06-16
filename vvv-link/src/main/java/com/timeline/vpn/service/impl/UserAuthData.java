package vpn.service.impl;

import com.timeline.vpn.model.po.UserPass;

import java.util.Arrays;
import java.util.List;

/**
 * @author gqli
 * @date 2017年1月6日 下午9:54:23
 * @version V1.0
 */
public class UserAuthData {
    private static List<UserPass> data;
    private static int index=0;
    static {
        data = Arrays.asList(new UserPass("usertest1", "usertest123"),
                new UserPass("usertest2", "usertest123"), new UserPass("usertest3", "usertest123"),
                new UserPass("usertest4", "usertest123"));
    }
    public static UserPass getOne(){
        UserPass pass = data.get(index);
        index = (index+1)%data.size();
        return pass;
    }
}

