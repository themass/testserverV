package com.timeline.vpn;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;

import com.sun.tools.classfile.StackMap_attribute.stack_map_frame;
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
        
        public static final String RESULT_MSG_DESC= "RESULT.MSG.DESC";
        public static final String RESULT_MSG_DESC1 = "RESULT.MSG.DESC1";
        public static final String RESULT_MSG_DESC2 = "RESULT.MSG.DESC2";
        public static final String RESULT_MSG_DESC3 = "RESULT.MSG.DESC3";

        
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
    public static final long MIN_TIME = 24*5 * 60 * 60 * 1000*1000;
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
    public static final String PLAYTYPE = "PLAY";

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
    
    public static final List<String> user = Arrays.asList("themass111","1103965695","110525","1157067035","1203578269","123456","123456789","1234567890","13425220655","1352735727","13652647957","1391273952","1473776707","1505408166","15141739791","1544206042","1665623198","1747578370","17685811385","1768789565","18177222867","18227914335","18484690549","18846781046","18930481562","1907412510","195578445","19960205","2066553133","2354460392","2411102429","253911907","260190325","294626441","306654268","3221585793","3327610490","35919819","374372142","392863074","416939422","50424371","6259","664414858","765403518","835779330","853726664","8610086","86890266","920578506","935900086","970524","987654321","ASFGDER","Accelerator","Alialiakisang","Asher0881","BasaraChilde","Chanchal","Cxhang","DNXdnx","Fragrancesurnhe","Friday","GAU","Gczy","Gin","HSHS","Hemithia","JMHQ","JOJO","JayDad","KANGTAO","LIV1118","Meng1","My8022052","MySandbox","OTOT","TTCACG","TTTPPP","Umegae","VenusQAQ","Yxw","a1398311841","a545145168","a934300309","aa2412593225","ai570289909","ai570289923","aiweinanhai","al233","alexlai","asd99","asdfghjkkkk","backkom","beebee","bishop","boduonganh","btwaljsn","calyen","catherine09","cc19981002","cenhy","cheungkit","colorfox","conor","cyw0572","dudu","elemental","fiyand","fj6259","fock","fuckthewall","fuyuxin","gao2435","gin718239187","gyyvpn","hakutie","hchaaa","hhyydd6666","hongziqinglaide","huangfulai","jiajin","jinmu","jzz","kingloverock","kqq1995","l1234","laukong","lhh544597","liaolidudududu","lindong53","liuhuakang","liushuiwuyi","lolv007","lu68086","lukacs","male152","mango123","maz313","mhb25","mikasau","miku5201314520","moxinhenji","myxox","nanashi140","noob2","omly","p1097800","poilsh","qjs15695580309","qq37549873","qq496941015","qust","qw1231111","qwelxj","qxykzx","sar","sexing1000","sfeer","shizufunv","sin","surphope","szwxzf","szx","tantzongwei","tfdsdj","tiandacore","tizheng","tuanzi","txc2703","victor110","wangyixun","wfs1900","wghdwbd","wh3396270441","whencheer","wodejb","wsxvc","wtm","wulei","wuzhi123","wxeka","wxy","wyk953","wzh4888487","xbxbzxb","xgh124158777","xh715","xiaoxuge111","xiewen","yuling","ywd008","yyk926127","yyqxer","zei6","zhg282624","zhixumo","zjw123","zqslzwzw","zx15348679",
            "zxc7728","zxcaq");

}
