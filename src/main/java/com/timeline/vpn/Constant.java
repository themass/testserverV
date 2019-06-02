package com.timeline.vpn;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;

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
        public static final String RESULT_HOST_ERROR = "RESULT.HOST.DATA";
        public static final String RESULT_EXIST_ERROR = "RESULT.ERROR.EXIST";
        public static final String RESULT_DATA_EMPETY_ERROR = "RESULT.ERROR.DATA.EMPETY";
        public static final String RESULT_USE_TIME_ERROR = "RESULT.ERROR.USE.TIME";
        public static final String RESULT_PERM_ERROR = "RESULT.ERROR.PERM";
        public static final String RESULT_VERSION_ERROR = "RESULT.ERROR.VERSION";
        public static final String RESULT_REG_REGCODE = "RESULT.ERROR.REGCODE";
        public static final String RESULT_ERROR_USER = "RESULT.ERROR.USER";
        public static final String RESULT_ERROR_NEEDUSER = "RESULT.ERROR.NEEDUSER";
        public static final String RESULT_ERROR_MANYUSER = "RESULT.ERROR.MANYUSER";
        public static final String RESULT_ERROR_DEV = "RESULT.ERROR.DEV";
        public static final String RESULT_ERROR_MANYUSERLOG = "RESULT.ERROR.MANYUSERLOG";
        
        
        public static final String RESULT_MSG_DESC= "RESULT.MSG.DESC";
        public static final String RESULT_MSG_DESC1 = "RESULT.MSG.DESC1";
        public static final String RESULT_MSG_DESC2 = "RESULT.MSG.DESC2";
        public static final String RESULT_MSG_DESC3 = "RESULT.MSG.DESC3";
        
        public static final String RESULT_MSG_DESC4 = "RESULT.MSG.DESC4";
        public static final String RESULT_MSG_DESC5 = "RESULT.MSG.DESC5";

        
    }
    public static class FileIpTYPE{
        public static final String BOOKWEB = "BOOK_WEB";
        public static final String BOOK = "BOOK";
        public static final String IMG = "IMG";
    }
    public static class FileIpExtra{
        public static final String ALL = "ALL";
        public static final String ZH = "ZH";
        public static final String OTHER = "OTHER";
    }
    public static class ResultErrno {
        public static final int ERRNO_SUCCESS = 0;
        public static final int ERRNO_SYSTEM = 10000;
        public static final int ERRNO_CLEAR_LOGIN = 1;
        public static final int ERRNO_NEED_LOGIN = 2;
        //
        public static final int ERRNO_PWD = 11001;// 用户名密码错误
        public static final int ERRNO_PARAM = 11002; // 参数错误
        public static final int ERRNO_DATA = 21000; // 参数错误
    }
    //用户分类 免费用户和VIP用户
    public static class UserLevel {
        public static final int LEVEL_FREE = 0;
        public static final int LEVEL_VIP = 1;
        public static final int LEVEL_VIP2 = 2;
        public static final int LEVEL_VIP3 = 3;
    }
    //用户组分类 未注册，注册，VIP 其中 未注册+注册=免费
    public static class UserGroup {
        public static final String RAD_GROUP_FREE = "VPN_FREE";
        public static final String RAD_GROUP_REG = "VPN_REG";
        public static final String RAD_GROUP_VIP = "VPN_VIP";
    }
    //福利级别 未注册，注册，vip
    public static class RecommendType {
        public static final int TYPE_OTHER = 0;
        public static final int TYPE_REG = 1;
        public static final int TYPE_VIP= 2;
    }
    public static class ServeType{
     // 0：免费，1vip，2高级vip
        public static final int SERVER_TYPE_FREE = 0;
        public static final int SERVER_TYPE_VIP = 1;
        public static final int SERVER_TYPE_VIP2 = 2;
    }
    public static class VideoShowType{
        // normal：原生，webview：webview打开
           public static final String NORMAL = "normal";
           public static final String WEBVIEW = "webview";
    }
    public static final String VIDEO_CHANNEL_WEB_PRF = "web_";
    
    public static final String NETTYPEA="NETTYPEA";
    public static final JsonResult RESULT_SUCCESS =
            new JsonResult(new RetInfoVo(true), Constant.ResultErrno.ERRNO_SUCCESS, null);
    public static final String HTTP_UA = "user-agent";
    public static final String VPN = "VPN";
    public static final String VPNB = "VPNB";
    public static final String VPNC = "VPNC";
    public static final String VPND = "VPND";
    public static final String LIFE = "LIFE";
    public static final String SEX = "SEX";
    public static final String SEX_TEMP = "SEX_TEMP";
    public static final String LANG_ZH="zh";
    
    public static final String VIDEO_EXT="avi,rmvb,3gp,wmv";
    public static final String MOVIE_TYPE="movie";
    
    public static final String HTTP_TOKEN_KEY = "Vpn-Token";
    public static final String HTTP_TOKEN_LIFE_KEY = "Life-Token";
    public static final String HTTP_TOKEN_SEX_KEY = "Sex-Token";
    public static final String HTTP_TOKEN_SEX_TEMP_KEY = "Sex-Token";
    public static final String ADMIN_NAME="themass";
    
    public static final String HTTP_ATTR_TOKEN = "token_key";
    public static final String HTTP_ATTR_RET = "ret_key";
    public static final String LANG = "Accept-Language";
    
    public static final String YOUMI_OFFADS="29abff90a29bc419";
    public static final int LOCATION_ALL = 0;
    public static final long FREE_TIME = 20 * 24 * 60 * 60;
    public static final long ADS_FAB_SCORE = 30;
    public static final long ADS_CLICK_SCORE = 30;
    public static final long ADS_REF_SCORE = 80;
    public static final long MIN_TIME = 24 * 60 * 60 * 1000;
    public static final int MIN_PAGESIZE = 30;
    public static final String RAD_PASS = "Cleartext-Password";
    public static final String RAD_EQ = ":=";
    public static final int SCORE_TO_VIP = 2500;
    public static final int SCORE_TO_VIP2 = 4500;
    public static final int SCORE_TO_VIP3 = 1000000000;
    public static final int RAD_PRIORITY_DEF = 2;
    public static String superMan = "FREE_VPN";
    public static final String STATE_TIME_USE="%s h, %sm, %ss";
    public static final String STATE_TRAFFIC_USE="%.2f";
    public static final String comma = ",";
    public static final String fen = ";";
    public static final String mao = ":";
    public static final String line = "_";
    public static final String PLAYTYPE = "SEXPLAY";

    public static final int dataType_RECOMMENT = 2;
    public static final int dataType_TEXT_CHANNEL = 3;
    public static final int dataType_SOUND_CHANNEL = 4;
    public static final int dataType_VIDEO_CHANNEL = 5;
    public static final int dataType_IMG_CHANNEL = 6;
    
    public static List<String> colorBg = Arrays.asList(
            "#887267","#dbcce7","#eddeb9",
            "#8b28dc","#b27edc","#f7dee1",
            "#887267","#e3c295", "#e98349",
            "#e3c295","#e0e8ef", "#f20c60",
            "#ea92b2","#ea1bdc", "#78b5ea",
            "#75ef67","#d0f744","#f7c744",
            "#f55220");
    
    
    public static Long CACHETIME=600l;
    public static Long CACHESIZE=100l;
    
    public static final List<String> user = Arrays.asList();
    public static final List<String> userNoCheck = Arrays.asList("");
    public static final List<String> userNodog = Arrays.asList("070580","27892120","themass123");

}
