package com.timeline.vpn;

import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.model.vo.RetInfoVo;

public class Constant {

    public static class ResultMsg {
        public static final String RESULT_SYSTEMERROR = "RESULT.ERROR.SYSTEM";
        public static final String RESULT_UNKNOWN = "RESULT.ERROR.UNKNOWN ";
        public static final String RESULT_NO_LOGIN = "RESULT.ERROR.NO.LOGIN";
        public static final String RESULT_LOGIN_ERROR = "RESULT.ERROR.LOGIN";
        public static final String RESULT_PWD_ERROR = "RESULT.ERROR.PWD";
        public static final String RESULT_LOGIN_PATTER = "RESULT.LOGIN.PATTER";
        public static final String RESULT_TOKEN_EXPIRE = "RESULT.ERROR.TOKEN.EXPIRE";
        public static final String RESULT_PARAM_ERROR = "RESULT.ERROR.PARAM";
        public static final String RESULT_DATA_ERROR = "RESULT.ERROR.DATA";
        public static final String RESULT_EXIST_ERROR = "RESULT.ERROR.EXIST";
        public static final String RESULT_DATA_EMPETY_ERROR = "RESULT.ERROR.DATA.EMPETY";
        public static final String RESULT_USE_TIME_ERROR = "RESULT.ERROR.USE.TIME";
        public static final String RESULT_PERM_ERROR = "RESULT.ERROR.PERM";
        public static final String RESULT_VERSION_ERROR = "RESULT.ERROR.VERSION";
        public static final String RESULT_REG_REGCODE = "RESULT.ERROR.REGCODE";
    }

    public static class ResultErrno {
        public static final int ERRNO_SUCCESS = 0;
        public static final int ERRNO_SYSTEM = 10000;
        public static final int ERRNO_CLEAR_LOGIN = 1;
        //
        public static final int ERRNO_PWD = 11001;// 用户名密码错误
        public static final int ERRNO_PARAM = 11002; // 参数错误
        public static final int ERRNO_DATA = 21000; // 参数错误
    }
    public static class UserLevel {
        public static final int LEVEL_FREE = 0;
        public static final int LEVEL_VIP = 1;
    }
    public static class UserGroup {
        public static final String RAD_GROUP_FREE = "VPN_FREE";
        public static final String RAD_GROUP_REG = "VPN_REG";
        public static final String RAD_GROUP_VIP = "VPN_VIP";
    }
    public static class RecommendType {
        public static final int TYPE_OTHER = 0;
        public static final int TYPE_REG = 1;
        public static final int TYPE_VIP= 2;
    }
    public static final JsonResult RESULT_SUCCESS =
            new JsonResult(new RetInfoVo(true), Constant.ResultErrno.ERRNO_SUCCESS, null);
    public static final String HTTP_UA = "user-agent";
    public static final String VPN = "VPN";
    public static final String LIFE = "LIFE";
    
    public static final String HTTP_TOKEN_KEY = "vpn-token";
    public static final String HTTP_TOKEN_LIFE_KEY = "life-token";
    public static final String HTTP_ATTR_TOKEN = "token_key";
    public static final String HTTP_ATTR_RET = "ret_key";
    public static final String LANG = "Accept-Language";
    // 0：免费地区，1vip，2高级vip
    public static final int SERVER_TYPE_FREE = 0;
    public static final int SERVER_TYPE_VIP = 1;
    public static final int SERVER_TYPE_HVIP = 2;
    public static final int LOCATION_ALL = 0;
    public static final long FREE_TIME = 20 * 24 * 60 * 60;
    public static final long ADS_FAB_SCORE = 10;
    public static final long ADS_CLICK_SCORE = 20;
    public static final long MIN_TIME = 9 * 60 * 60 * 1000;
    public static final int MIN_PAGESIZE = 30;
    public static final String RAD_PASS = "Cleartext-Password";
    public static final String RAD_EQ = ":=";
    public static final int SCORE_TO_VIP = 150;
    public static final int RAD_PRIORITY_DEF = 2;
    public static String superMan = "FREE_VPN";
    public static final String STATE_TIME_USE="%s h, %sm, %ss";
    public static final String STATE_TRAFFIC_USE="%.2f";
    public static final String comma = ",";
    public static final String fen = ";";
    public static final String mao = ":";
}
