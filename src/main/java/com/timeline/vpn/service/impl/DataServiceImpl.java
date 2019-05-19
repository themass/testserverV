package com.timeline.vpn.service.impl;

import java.util.Arrays;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.support.ResourceBundleMessageSource;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import com.github.pagehelper.Page;
import com.github.pagehelper.PageHelper;
import com.google.common.collect.Lists;
import com.timeline.vpn.Constant;
import com.timeline.vpn.VoBuilder;
import com.timeline.vpn.VoBuilder.BuildAction;
import com.timeline.vpn.dao.db.AppInfoDao;
import com.timeline.vpn.dao.db.DomainDao;
import com.timeline.vpn.dao.db.IWannaDao;
import com.timeline.vpn.dao.db.VersionDao;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.DevApp;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.po.AppInfoPo;
import com.timeline.vpn.model.po.AppVersion;
import com.timeline.vpn.model.po.DomainPo;
import com.timeline.vpn.model.po.IWannaPo;
import com.timeline.vpn.model.po.RecommendPo;
import com.timeline.vpn.model.po.WeixinAccessPo;
import com.timeline.vpn.model.vo.AppInfoVo;
import com.timeline.vpn.model.vo.DomainVo;
import com.timeline.vpn.model.vo.IWannaVo;
import com.timeline.vpn.model.vo.IWannnWeixinVo;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.RecommendVo;
import com.timeline.vpn.model.vo.StateUseVo;
import com.timeline.vpn.model.vo.VersionInfoVo;
import com.timeline.vpn.model.vo.VipDescVo;
import com.timeline.vpn.service.DataService;
import com.timeline.vpn.service.DataVideoService;
import com.timeline.vpn.service.UserService;
import com.timeline.vpn.service.impl.handle.recommend.RecommendServiceProxy;
import com.timeline.vpn.util.DeviceUtil;
import com.timeline.vpn.util.HttpCommonUtil;
import com.timeline.vpn.util.HttpRequest;
import com.timeline.vpn.util.JsonUtil;
import com.timeline.vpn.util.cache.CacheUtil;
import com.timeline.vpn.util.cache.MemCache;

/**
 * @author gqli
 * @date 2016年3月10日 下午4:45:36
 * @version V1.0
 */
@Service
public class DataServiceImpl implements DataService {
  private static final Logger LOGGER =
      LoggerFactory.getLogger(DataServiceImpl.class);
    @Autowired
    private VersionDao versionDao;
    @Autowired
    private RecommendServiceProxy recommendServiceProxy;
    @Autowired
    private IWannaDao iWannaDao;
    @Autowired
    private UserService userService;
    @Autowired
    private AppInfoDao appInfoDao;
    @Autowired
    private DataVideoService dataVideoService;
    @Autowired
    private ResourceBundleMessageSource messagesource;
    @Autowired
    private DomainDao domainDao;
    private MemCache memCache= new MemCache();
    @Override
    public InfoListVo<RecommendVo> getRecommendPage(BaseQuery baseQuery, PageBaseParam param) {
        //未登录   ， 登录，  VIP
        final String baseUrl = CdnChooseUtil.getImageBaseUrl(baseQuery.getAppInfo().getUserIp());
        int type = baseQuery.getUser()==null?Constant.RecommendType.TYPE_OTHER:
            (baseQuery.getUser().getLevel()==Constant.UserLevel.LEVEL_FREE?Constant.RecommendType.TYPE_REG:Constant.RecommendType.TYPE_VIP);
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<RecommendPo> poList = recommendServiceProxy.getPage(type);
        return VoBuilder.buildPageInfoVo((Page<RecommendPo>) poList, RecommendVo.class,new BuildAction<RecommendPo,RecommendVo>(){

            @Override
            public void action(RecommendPo i, RecommendVo t) {
                if(!StringUtils.isEmpty(baseUrl) && !StringUtils.isEmpty(i.getImg())){
                    t.setImg(baseUrl+i.getImg());
                }
            }
            
        });
    }
    @Override
    public InfoListVo<RecommendVo> getRecommendMoviePage(BaseQuery baseQuery) {
        return dataVideoService.getVideoChannel(baseQuery,Constant.MOVIE_TYPE);
    }
    @Override
    public InfoListVo<RecommendVo> getRecommendMoviePage2(BaseQuery baseQuery) {
        return dataVideoService.getVideoChannel(baseQuery,Constant.MOVIE_TYPE);
    }
    @Override
    public InfoListVo<RecommendVo> getRecommendNightPage(BaseQuery baseQuery, PageBaseParam param) {
        return getRecommendVipPage(baseQuery,param);
    }
 
    @Override
    public InfoListVo<RecommendVo> getRecommendAreaPage(BaseQuery baseQuery, PageBaseParam param) {
        if(baseQuery.getUser()!=null || baseQuery.getUser().getLevel()<Constant.UserLevel.LEVEL_VIP2) {
            return new InfoListVo<RecommendVo>();
        }
        final String baseUrl = CdnChooseUtil.getImageBaseUrl(baseQuery.getAppInfo().getUserIp());
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<RecommendPo> poList = recommendServiceProxy.getAreaPage();
        return VoBuilder.buildPageInfoVo((Page<RecommendPo>) poList, RecommendVo.class,new BuildAction<RecommendPo,RecommendVo>(){

            @Override
            public void action(RecommendPo i, RecommendVo t) {
                if(!StringUtils.isEmpty(baseUrl) && !StringUtils.isEmpty(i.getImg())){
                    t.setImg(baseUrl+i.getImg());
                }
            }
             
        });
    }
    @Override
    public InfoListVo<RecommendVo> getRecommendVipPage( final BaseQuery baseQuery, PageBaseParam param) {
        final String baseUrl = CdnChooseUtil.getImageBaseUrl(baseQuery.getAppInfo().getUserIp());
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<RecommendPo> poList = recommendServiceProxy.getVipPage();
        return VoBuilder.buildPageInfoVo((Page<RecommendPo>) poList, RecommendVo.class,new BuildAction<RecommendPo,RecommendVo>(){

            @Override
            public void action(RecommendPo i, RecommendVo t) {
                if(!StringUtils.isEmpty(baseUrl) && !StringUtils.isEmpty(i.getImg())){
                    t.setImg(baseUrl+i.getImg());
                }
            }
            
        });
    }
    @Override
    public VersionInfoVo getMaxVersion(DevApp app,String channel) {
      if(!StringUtils.isEmpty(app.getNetType())) {
        channel = app.getNetType()+"_"+channel;
      }  
//      LOGGER.info("channel ="+channel);
      VersionInfoVo cache = (VersionInfoVo)memCache.getValue(CacheUtil.getVersion(channel), Constant.CACHETIME, Constant.CACHESIZE);
//      LOGGER.info("cache0 ="+cache);
      if(cache!=null) {
          return cache;
      }
      cache = VoBuilder.buildVo(versionDao.getLast(app.getPlatform(),channel), VersionInfoVo.class,null);
//      LOGGER.info("cache1 ="+cache);
      cache.setUpdate(true);
      memCache.putValue(CacheUtil.getVersion(channel), cache,Constant.CACHETIME, Constant.CACHESIZE);
      return cache;
    }
    @Override
    public VersionInfoVo getVersion(BaseQuery baseQuery,String platform,String channel) {
      if(!StringUtils.isEmpty(baseQuery.getAppInfo().getNetType())) {
        channel = baseQuery.getAppInfo().getNetType()+"_"+channel;
      }  
      AppVersion vpnVer = versionDao.getLast(platform,channel);
      VersionInfoVo vo = VoBuilder.buildVo(vpnVer, VersionInfoVo.class,null);
        vo.setAdsShow(false);
        vo.setLogUp(true);
        vo.setVpnUrl(vpnVer.getUrl());
//        if(!channel.contains(Constant.VPN)){
//            AppVersion vpnVer = versionDao.getLast(platform,Constant.VPN);
//            vo.setVpnUrl(vpnVer.getUrl());
//        }
        if(baseQuery!=null){
            String userName = baseQuery.getUser()==null?null:baseQuery.getUser().getName();
            userService.updateDevUseinfo(baseQuery.getAppInfo(),userName);
            if(channel.contains(Constant.VPN)){
                if(baseQuery.getUser()!=null){
                    StateUseVo state = userService.stateUse(Arrays.asList(baseQuery.getUser().getName(),baseQuery.getAppInfo().getDevId()));
                    vo.setStateUse(state);  
                    vo.setTraf(state.getTraf());
                }else{
                    StateUseVo state = userService.stateUse(Arrays.asList(baseQuery.getAppInfo().getDevId()));
                    vo.setStateUse(state); 
                    vo.setTraf(state.getTraf());
                }
            }
        }
//        LOGGER.info("traf="+vo.getTraf());
        VipDescVo desc = new VipDescVo(); 
//        desc.setDesc("每周扣除150积分；点广告赚积分");
//        desc.setDesc1("2100积分=VIP1；4100积分=VIP2");
//        desc.setDesc2("邀请用户40积分/人；大于5人送vip3-15天；\\n大于10人送vip3-30天；\\n大于15人 送vip3-50天+pc1个月/200G流量");
        desc.setDesc3(getMessage(Constant.ResultMsg.RESULT_MSG_DESC5, baseQuery.getAppInfo().getLang()));
        if(Constant.VPNB.equals(baseQuery.getAppInfo().getNetType())) {
          desc.setDesc("赚积分兑换VIP：详见“关于”");
          desc.setDesc1("折扣：VIP1-25/月，250/年\n折扣：VIP2-35/月，300/年");
        }else if(Constant.VPNC.equals(baseQuery.getAppInfo().getNetType())) {
            desc.setDesc(getMessage(Constant.ResultMsg.RESULT_MSG_DESC, baseQuery.getAppInfo().getLang()));
            desc.setDesc1(getMessage(Constant.ResultMsg.RESULT_MSG_DESC3, baseQuery.getAppInfo().getLang()));
            desc.setDesc2(getMessage(Constant.ResultMsg.RESULT_MSG_DESC1, baseQuery.getAppInfo().getLang()));
            if(Constant.LANG_ZH.equals(baseQuery.getAppInfo().getLang())) {
                LOGGER.info("中国灯塔用户  1000008024"); 
                vo.setMinBuild("1000008024");
                vo.setMaxBuild("1000008024"); 
                vo.setContent("灯塔提示：系统维护一周时间\n请使用AFree,账号通用\nQQ群：957430787\nhttp:\\\\sspacee.com 下载\n无法解析？点击分享有下载链接");
                vo.setVpnUrl("http://file.sspacee.com/file/app/FreeV9N_11818.apk");
                vo.setUrl("http://file.sspacee.com/file/app/FreeV9N_11818.apk");
                desc.setDesc("灯塔系统维护一周\n请使用Afree\n无法解析？点击分享\n就可以找到链接");
                desc.setDesc2("QQ群：957430787");
                
            }
        }else if(Constant.VPND.equals(baseQuery.getAppInfo().getNetType())) {
            desc.setDesc(getMessage(Constant.ResultMsg.RESULT_MSG_DESC, baseQuery.getAppInfo().getLang()));
            desc.setDesc1(getMessage(Constant.ResultMsg.RESULT_MSG_DESC3, baseQuery.getAppInfo().getLang()));
            desc.setDesc2(getMessage(Constant.ResultMsg.RESULT_MSG_DESC1, baseQuery.getAppInfo().getLang()));
        }else if(Constant.SEX.equals(baseQuery.getAppInfo().getChannel())) {
            desc.setDesc(getMessage(Constant.ResultMsg.RESULT_MSG_DESC, baseQuery.getAppInfo().getLang()));
            desc.setDesc1(getMessage(Constant.ResultMsg.RESULT_MSG_DESC4, baseQuery.getAppInfo().getLang()));
            desc.setDesc2(getMessage(Constant.ResultMsg.RESULT_MSG_DESC5, baseQuery.getAppInfo().getLang()));
        }else if(Constant.PLAYTYPE.equals(baseQuery.getAppInfo().getNetType())){
            desc.setDesc(getMessage(Constant.ResultMsg.RESULT_MSG_DESC, baseQuery.getAppInfo().getLang()));
            desc.setDesc1(getMessage(Constant.ResultMsg.RESULT_MSG_DESC4, baseQuery.getAppInfo().getLang()));
            desc.setDesc2(getMessage(Constant.ResultMsg.RESULT_MSG_DESC5, baseQuery.getAppInfo().getLang()));
        }else {
          desc.setDesc(getMessage(Constant.ResultMsg.RESULT_MSG_DESC, baseQuery.getAppInfo().getLang()));
          desc.setDesc1(getMessage(Constant.ResultMsg.RESULT_MSG_DESC3, baseQuery.getAppInfo().getLang()));
          desc.setDesc2(getMessage(Constant.ResultMsg.RESULT_MSG_DESC1, baseQuery.getAppInfo().getLang()));
        }
        if(baseQuery!=null&&baseQuery.getUser()!=null)
            desc.setScore(baseQuery.getUser().getScore());
        vo.setVitamioExt(Constant.VIDEO_EXT);
        vo.setVipDesc(desc);
        vo.setQq("957430787");
        return vo;
    }
    private String getMessage(String key, String lang) {
      return messagesource.getMessage(key, null, DeviceUtil.getLocale(lang));
  }

    @Override
    public InfoListVo<RecommendVo> getRecommendRecPage(BaseQuery baseQuery, PageBaseParam param) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<RecommendPo> poList = recommendServiceProxy.getRecoPage();
        return VoBuilder.buildPageInfoVo((Page<RecommendPo>) poList, RecommendVo.class,null);
    }

    @Override
    public InfoListVo<AppInfoVo> getAllApp(BaseQuery baseQuery) {
        List<AppInfoPo> list = appInfoDao.getAll();
        return VoBuilder.buildListInfoVo(list, AppInfoVo.class,null);
    }
    @Override
    public InfoListVo<AppInfoVo> getAllDon(BaseQuery baseQuery) {
        List<AppInfoPo> list = appInfoDao.getAllDon();
        return VoBuilder.buildListInfoVo(list, AppInfoVo.class,null);
    }
    @Override
    public InfoListVo<IWannaVo> getIwannaPage(BaseQuery baseQuery, PageBaseParam param) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        Page<IWannaPo> data = null;
        if(DeviceUtil.isAdmin(baseQuery)) {
            data = (Page<IWannaPo>) iWannaDao.getAll();
        }else {
            String name = baseQuery.getUser()!=null?baseQuery.getUser().getName():Constant.ADMIN_NAME;
            data = (Page<IWannaPo>) iWannaDao.getPage(baseQuery.getAppInfo().getChannel()+baseQuery.getAppInfo().getNetType(),name);
        }
        return VoBuilder.buildIWannaPageInfoVo(data, baseQuery);
    }
    @Override
    public InfoListVo<IWannnWeixinVo> getIwannaWeiXin() {
        PageHelper.startPage(1, 30);
        Page<IWannaPo> data = (Page<IWannaPo>) iWannaDao.getPage(null,Constant.ADMIN_NAME);
        return VoBuilder.buildListInfoVo(data, IWannnWeixinVo.class, null);
    }
    @Override
    public IWannaVo addIwanna(BaseQuery baseQuery, String content) {
        IWannaPo po = new IWannaPo();
        po.setContent(content);
        po.setCreateTime(new Date());
        po.setLikes(0);
        po.setLikeUsers(Constant.superMan);
        po.setName(baseQuery.getUser().getName());
        po.setIp(baseQuery.getAppInfo().getUserIp());
        po.setAppName(baseQuery.getAppInfo().getChannel()+baseQuery.getAppInfo().getNetType());
        iWannaDao.insert(po);
        sendMsg(content+"--"+baseQuery.getUser().getName()+"--"+baseQuery.getAppInfo().getChannel());
        return VoBuilder.buildIWannaVo(po, baseQuery.getUser().getName());
    }

    @Override
    public void addIwannaLike(BaseQuery baseQuery, long id) {
        IWannaPo po = iWannaDao.get(id);
        po.setLikes(po.getLikes() + 1);
        if (baseQuery.getUser()!=null && !po.getLikeUsers().contains(baseQuery.getUser().getName())) {
            po.setLikeUsers(po.getLikeUsers() + "," + baseQuery.getUser().getName());
        }
        iWannaDao.likeFeed(po);

    }
    @Override
    public InfoListVo<IWannaVo> getIwannaScorePage(BaseQuery baseQuery, PageBaseParam param) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        Page<IWannaPo> data = null;
        if(DeviceUtil.isAdmin(baseQuery)) {
          data = (Page<IWannaPo>) iWannaDao.getAllFeed();
        }else {
            String name = baseQuery.getUser()!=null?baseQuery.getUser().getName():Constant.ADMIN_NAME;
            data = (Page<IWannaPo>) iWannaDao.getPageFeed(baseQuery.getAppInfo().getChannel()+baseQuery.getAppInfo().getNetType(),name);
        }
        return VoBuilder.buildIWannaPageInfoVo(data, baseQuery);
    }

    @Override
    public IWannaVo addIwannaScore(BaseQuery baseQuery, String content) {
        IWannaPo po = new IWannaPo();
        po.setContent(content);
        po.setCreateTime(new Date());
        po.setLikes(0);
        po.setLikeUsers(Constant.superMan);
        po.setName(baseQuery.getUser().getName());
        po.setIp(baseQuery.getAppInfo().getUserIp());
        po.setAppName(baseQuery.getAppInfo().getChannel()+baseQuery.getAppInfo().getNetType());
        iWannaDao.insertFeed(po);
        sendMsg(content+"--"+baseQuery.getUser().getName()+"--"+baseQuery.getAppInfo().getChannel());
        return VoBuilder.buildIWannaVo(po, baseQuery.getUser().getName());
    }

    @Override
    public void addIwannaScoreLike(BaseQuery baseQuery, long id) {
        IWannaPo po = iWannaDao.getFeed(id);
        po.setLikes(po.getLikes() + 1);
        if (baseQuery.getUser()!=null && !po.getLikeUsers().contains(baseQuery.getUser().getName())) {
            po.setLikeUsers(po.getLikeUsers() + "," + baseQuery.getUser().getName());
        }
        iWannaDao.likeFeed(po);

    }
    @Override
    public DomainVo getAllDomain(BaseQuery baseQuery) {
         List<DomainPo>list= domainDao.getList(baseQuery.getAppInfo().getChannel());
         DomainVo vo = new DomainVo();
         List<String> domain = Lists.newArrayList();
         for(DomainPo po:list) {
             domain.add(po.getDns());
         }
         vo.setDns(domain);
         return vo;
    }
    /**
     * appID
wxe75fbe15f3e3fdff
appsecret
76eb1ba24fb05a193cfa2569597c432f
     */
    @Override
    public String getAsstoken() {
      String token = null;//cacheService.get("ASS_TOKEN");
      if(StringUtils.isEmpty(token)) {
          Map<String, String> params = new HashMap<>();
          params.put("grant_type", "client_credential");
          params.put("appid", "wxe75fbe15f3e3fdff");
          params.put("secret", "76eb1ba24fb05a193cfa2569597c432f");
          Map<String, String> headers = new HashMap<>();
          headers.put("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8");
    //      headers.put("grant_type", "client_credential");
    //      headers.put("grant_type", "client_credential");
          String json = HttpCommonUtil.sendGet("https://api.weixin.qq.com/cgi-bin/token", "utf-8", params, headers);
          WeixinAccessPo po = JsonUtil.readValue(json, WeixinAccessPo.class);
          token = po.getAccess_token();
//          LOGGER.info("token="+token);
//          cacheService.put("ASS_TOKEN", token, 3);
      }
      return token;
    }
    private void getOpenId() {
      String token = getAsstoken();
      Map<String, String> params = new HashMap<>();
      params.put("access_token", token);
//      params.put("next_openid", "NEXT_OPENID");
      String url = "https://api.weixin.qq.com/cgi-bin/user/get";
      String json = HttpCommonUtil.sendGet(url, "utf-8", params,null);
    }
    public void sendMsg(String msg) {
      try {
        Map<String, String> headers = new HashMap<>();
        headers.put("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8");
        headers.put("Content-type", "application/json; charset=utf-8");
        
        String token = getAsstoken();
        String url = "https://api.weixin.qq.com/cgi-bin/message/mass/send?access_token="+token;
        Map<String, String> content = new HashMap<>();
        content.put("content", msg.replace("VPN", "v9n").replaceAll("vpn", "v9n"));
        
        Map<String, Object> params = new HashMap<>();
        params.put("touser",Arrays.asList("oTzH21bdL3u19PE5UR11Mc-PLZ_Y","oTzH21TIeKfp9sE-YZZwJOyQ7zvQ"));
        params.put("msgtype", "text");
        params.put("text", content);
        String pcontent = JsonUtil.writeValueAsString(params);
       
          String reString = HttpRequest.sendPost(url, pcontent);
  //        StringEntity entity = new StringEntity(pcontent, ContentType.APPLICATION_JSON);
  //        entity.setContentType("UTF-8");
  //        String reString = HttpCommonUtil.sendPostWithEntity(url, entity, headers, true);
//          LOGGER.info("发送微信消息："+reString);
      }catch (Exception e) {
        LOGGER.error("发送微信消息： 失败");
      }
    }
    public static void main(String[]args) {
      DataServiceImpl impl = new DataServiceImpl();
//      String token = impl.getAsstoken();
//      System.out.println(token);
      impl.sendMsg("test侧事故续爱选打算");
//        impl.getOpenId();
    }
    

}

