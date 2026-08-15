package com.timeline.vpn.service.impl;

import cn.hutool.core.codec.Base64Encoder;
import com.github.pagehelper.Page;
import com.github.pagehelper.PageHelper;
import com.timeline.vpn.Constant;
import com.timeline.vpn.VoBuilder;
import com.timeline.vpn.dao.db.VideoDao;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.param.PageBaseParam;
import com.timeline.vpn.model.po.*;
import com.timeline.vpn.model.vo.InfoListVo;
import com.timeline.vpn.model.vo.RecommendVo;
import com.timeline.vpn.service.DataVideoService;
import com.timeline.vpn.common.utils.HttpCommonUtil;
import com.timeline.vpn.util.JsonUtil;
import org.apache.commons.lang3.StringUtils;
import org.jsoup.Connection;
import org.jsoup.Jsoup;
import org.jsoup.nodes.Document;
import org.jsoup.nodes.Element;
import org.jsoup.select.Elements;
import java.io.BufferedReader;
import java.io.InputStreamReader;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.net.URLEncoder;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
/**
 * @author gqli
 * @date 2016年3月10日 下午4:45:36
 * @version V1.0
 */
@Service
public class DataVideoServiceImpl implements DataVideoService {
    private static final Logger LOGGER =
            LoggerFactory.getLogger(DataVideoServiceImpl.class);
    @Autowired
    private VideoDao videoDao;
    @Override
    public InfoListVo<RecommendVo> getVideoPage(BaseQuery baseQuery, PageBaseParam param) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<VideoPo> list = videoDao.getPage();
        return VoBuilder.buildPageInfoVo((Page<VideoPo>)list, RecommendVo.class,new VoBuilder.BuildAction<VideoPo,RecommendVo>(){
            @Override
            public void action(VideoPo i, RecommendVo t) {
                t.setActionUrl(i.getUrl()); 
                t.setTitle(i.getName());
                t.setImg(i.getPic());
                t.setAdsPopShow(false);
                t.setAdsShow(true); 
                t.setParam(i.getUrl());
                t.setDataType(Constant.dataType_VIDEO_CHANNEL);
            }
        });
    }

    @Override
    public InfoListVo<RecommendVo> getVideoChannel(BaseQuery baseQuery,String channel) {
        List<VideoChannelPo> list = videoDao.getChannel(channel);
        List<VideoChannelPo> list2= new ArrayList<>();
        if(baseQuery.getAppInfo().getNetType()!=null && baseQuery.getAppInfo().getNetType().contains(Constant.PLAYTYPE)) {
            for(VideoChannelPo po:list) {
                if(po.getM()==1) {
                    list2.add(po);
                }
            }
        }else {
            list2 = list;
        }
        return VoBuilder.buildListInfoVo(list2, RecommendVo.class,new VoBuilder.BuildAction<VideoChannelPo,RecommendVo>(){
            @Override
            public void action(VideoChannelPo i, RecommendVo t) {
                t.setActionUrl(i.getUrl());
                t.setTitle(i.getName());
                t.setImg(i.getPic());
                t.setAdsPopShow(false);
                t.setAdsShow(true);
                t.setParam(i.getChannel());
                t.setShowLogo(i.getCount()+"部");
                t.setDataType(Constant.dataType_VIDEO_CHANNEL);
                t.setChannelType(i.getChannelType());
            }
        });
    }

    @Override
    public InfoListVo<RecommendVo> getVideoChannelItemsPage(BaseQuery baseQuery,
            PageBaseParam param, String channel,String keywork,String channelOrg) {
        VideoChannelPo po = videoDao.getOneChannel(channelOrg);
        List<VideoPo> list = null;
        if(!StringUtils.isEmpty(channelOrg) && channelOrg.startsWith("one_")) {
            channel = channelOrg;
        }
        String channelType = po.getChannelType();
        //关键字检索-》使用baseurl来检索
        if(!StringUtils.isEmpty(keywork)) {
            channel = null;
        }
        if(!StringUtils.isEmpty(keywork)&& keywork.startsWith(Constant.comma)) {
            channel = channelOrg;
            keywork = keywork.replace(Constant.comma,"");
        }
        if(!StringUtils.isEmpty(keywork)&& keywork.startsWith(Constant.commaCH)) {
            channel = channelOrg;
            keywork = keywork.replace(Constant.commaCH,"");
        }
        if(!StringUtils.isEmpty(keywork) && keywork.contains(Constant.line)) {
            //全局检索
            keywork = keywork.replace(Constant.line,"");
            channel = null;
            channelType = "movie";
            if(baseQuery.getUser()!=null && baseQuery.getUser().getLevel()>0) {
                channelType = null;
            }
        }
        PageHelper.startPage(param.getStart(), param.getLimit());
        LOGGER.info("channel="+channel+"-keywork="+keywork+"-channelType="+channelType+"-channelOrg"+channelOrg+"-po="+po.toString());
        if(!StringUtils.isEmpty(keywork) && keywork.contains(Constant.asc)){
            keywork = keywork.replace(Constant.asc,"");
            list = videoDao.getChannelItemsAsc(channel,keywork,channelType, null);
        }else{
            list = videoDao.getChannelItems(channel,keywork,channelType, null);
        }

        return VoBuilder.buildPageInfoVo((Page<VideoPo>)list, RecommendVo.class,new VoBuilder.BuildAction<VideoPo,RecommendVo>(){
            @Override
            public void action(VideoPo i, RecommendVo t) {
                t.setActionUrl(i.getUrl());
                t.setTitle(i.getName());
                t.setImg(i.getPic());
                t.setAdsPopShow(false);
                t.setAdsShow(true);
                t.setParam(i.getBaseurl());
                t.setExtra(i.getVideoType());
                t.setDataType(Constant.dataType_VIDEO_CHANNEL);
                if(i.getBaseurl()!=null && i.getBaseurl().contains("hsex")){
                    t.setNeedLazyUrl(true);
                }else if(i.getBaseurl()!=null && i.getBaseurl().contains("rou")){
                    t.setNeedLazyUrl(true);
                }else if(i.getBaseurl()!=null && i.getBaseurl().contains("rfd0i4")){
                    t.setNeedLazyUrl(true);
                }else{
                    t.setNeedLazyUrl(false);
                }
            }
        });
    }

    @Override
    public InfoListVo<RecommendVo> getVideoUserPage(BaseQuery baseQuery, PageBaseParam param,String channel, String keyword) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<VideoUserPo> list = videoDao.getUsers(channel, keyword);
        return VoBuilder.buildPageInfoVo((Page<VideoUserPo>)list, RecommendVo.class,new VoBuilder.BuildAction<VideoUserPo,RecommendVo>(){
            @Override
            public void action(VideoUserPo i, RecommendVo t) {
                t.setActionUrl(i.getUserId());
                t.setTitle(i.getName());
                t.setImg(i.getPic());
                t.setAdsPopShow(false);
                t.setAdsShow(true);
                t.setParam(i.getChannel());
                t.setShowLogo(i.getCount()+"集");
                t.setDataType(Constant.dataType_VIDEO_CHANNEL);
                t.setChannelType(i.getChannelType());
            }
        });
    }

    @Override
    public InfoListVo<RecommendVo> getVideoUserItemsPage(BaseQuery baseQuery, PageBaseParam param,
            String userId,String keyword) {
        VideoUserPo po = videoDao.getUserByUserId(userId);
        PageHelper.startPage(param.getStart(), param.getLimit());
        String channel = po.getChannel();
        if(!StringUtils.isEmpty(keyword)) {
            userId = null;
            if(keyword.contains(Constant.line)) {
                keyword = keyword.substring(0, keyword.indexOf(Constant.line));
                userId = null;
                channel = null;
            }
        }
        
        List<VideoUserItemPo> list = videoDao.getUserItems(channel,userId,keyword);
        return VoBuilder.buildPageInfoVo((Page<VideoUserItemPo>)list, RecommendVo.class,new VoBuilder.BuildAction<VideoUserItemPo,RecommendVo>(){
            @Override
            public void action(VideoUserItemPo i, RecommendVo t) {
                t.setActionUrl(i.getUrl());
                t.setTitle(i.getName());
                t.setImg(i.getPic());
                t.setAdsPopShow(false);
                t.setAdsShow(true);
                t.setParam(i.getUserId());
                t.setExtra(i.getVideoType());
                t.setDataType(Constant.dataType_VIDEO_CHANNEL);
            }
        });
    }

    @Override
    public InfoListVo<RecommendVo> getVideoTvItemPage(BaseQuery baseQuery, PageBaseParam param,
            String channel) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        Page<VideoPo>list = (Page<VideoPo>)videoDao.getTvItem(channel);
        return VoBuilder.buildPageInfoVo(list, RecommendVo.class,new VoBuilder.BuildAction<VideoPo,RecommendVo>(){
            @Override
            public void action(VideoPo i, RecommendVo t) {
                t.setActionUrl(i.getUrl());
                t.setTitle(i.getName());
                t.setImg(i.getPic());
                t.setAdsPopShow(false);
                t.setAdsShow(true);
                t.setParam(i.getBaseurl());
                t.setExtra(i.getVideoType());
                t.setDataType(Constant.dataType_VIDEO_CHANNEL);
            }
        });
    }

    @Override
    public InfoListVo<RecommendVo> getVideoTvChannelPage(BaseQuery baseQuery,  PageBaseParam param,String channelType,
            String keyword) {
        PageHelper.startPage(param.getStart(), param.getLimit());
        List<VideoChannelPo> list = videoDao.getTvChannel(channelType, keyword);
        return VoBuilder.buildPageInfoVo((Page<VideoChannelPo>)list, RecommendVo.class,new VoBuilder.BuildAction<VideoChannelPo,RecommendVo>(){
            @Override
            public void action(VideoChannelPo i, RecommendVo t) {
                t.setActionUrl(i.getUrl());
                t.setTitle(i.getName());
                t.setImg(i.getPic());
                t.setAdsPopShow(false);
                t.setAdsShow(true);
                t.setParam(i.getUrl());
                t.setShowLogo(i.getCount()+"集");
                t.setDataType(Constant.dataType_VIDEO_CHANNEL);
            }
        });
    }

    @Override
    public RecommendVo getVideoUrl(BaseQuery baseQuery, PageBaseParam param, long id) {
            VideoPo item = videoDao.getOneItem(id);
            if(item.getBaseurl().contains("rou.")){
                String data = HttpCommonUtil.sendGet(item.getPath().replace("https://rou.video","https://rou.video/api"));
                RouVideoBean rouVideoBean = JsonUtil.readValue(data, RouVideoBean.class);
                String urlData = HttpCommonUtil.sendGet(rouVideoBean.getVideo().getVideoUrl());
                String regex = "^https.*$";
                // 创建 Pattern 对象
                Pattern pattern = Pattern.compile(regex, Pattern.MULTILINE);
                // 创建 matcher 对象
                Matcher matcher = pattern.matcher(urlData);
                // 检查是否匹配
                String url= "";
                if (matcher.find()) {
                    url = matcher.group();
                }
                LOGGER.info("data={},url={}",data,url);
                RecommendVo vo = new RecommendVo();
                vo.setActionUrl(url);
                vo.setTitle(item.getName());
                vo.setImg(item.getPic());
                vo.setAdsPopShow(false);
                vo.setAdsShow(true);
                vo.setParam(item.getBaseurl());
                vo.setExtra(item.getVideoType());
                vo.setDataType(Constant.dataType_VIDEO_CHANNEL);
                return vo;
            }
            if(item.getBaseurl().contains("rfd0i4.")){
                String data = HttpCommonUtil.sendGet(item.getPath());
                String url = fetchCdnUrl(data);
                LOGGER.info("data={},url={}",data,url);
                RecommendVo vo = new RecommendVo();
                vo.setActionUrl(url);
                vo.setTitle(item.getName());
                vo.setImg(item.getPic());
                vo.setAdsPopShow(false);
                vo.setAdsShow(true);
                vo.setParam(item.getBaseurl());
                vo.setExtra(item.getVideoType());
                vo.setDataType(Constant.dataType_VIDEO_CHANNEL);
                return vo;
            }
            //hsex
            try {
                Map<String ,String > header = new HashMap<>();
//                header.put("User-Agent","Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36");
//                header.put("Referer",item.getBaseurl());
//                header.put("Accept-Encoding","gzip, deflate, br");
//                header.put("Accept","text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7");
//                header.put("Cookie","_ga=GA1.1.611983894.1716478735; __PPU_puid=7372220048289729256; __PPU_CAIFRQ=AC3I8gAAAAAAAAAB; __PPU_CAIFRT=AC3I8gAAAABmkgnQ; hid=pe23b18i9rui36af8tlct1hac4; cf_clearance=qXy7LEl8vOIYqy0owpkqfAJYKf7QKaH.9HOiHUVDlg0-1722351879-1.0.1.1-k8PaqqzEipqOUQdwV2p3JevlLcWdIBzw.b1E4LmRgp7dmucl076.09HpcxPE_8jJ3XqSJNSh1B5mrVpLlPqtQQ; UGVyc2lzdFN0b3JhZ2U=%7B%7D; bnState_1871751={\"impressions\":11,\"delayStarted\":0}; _ga_ECF2QFGQ9G=GS1.1.1722351875.8.1.1722353472.0.0.0");
                String data = fetch(item.getPath());
                Connection conn = Jsoup.connect(item.getPath()).headers(header);
//                Document doc = conn.get();
                Document doc = Jsoup.parse(data);
                Elements links = doc.select("source");
                LOGGER.info("url---"+item.getPath());
                LOGGER.info("title------"+doc.title());
//                LOGGER.info("linksize---"+links.size());
                for (Element link : links) {
                    LOGGER.info("links---"+link.html());
                    String url = link.attr("src");
                    LOGGER.info("links---url="+url);

                    RecommendVo vo = new RecommendVo();
                    vo.setActionUrl(url);
                    vo.setTitle(item.getName());
                    vo.setImg(item.getPic());
                    vo.setAdsPopShow(false);
                    vo.setAdsShow(true);
                    vo.setParam(item.getBaseurl());
                    vo.setExtra(item.getVideoType());
                    vo.setDataType(Constant.dataType_VIDEO_CHANNEL);
                    return vo;
                }
            } catch (Exception e) {
                LOGGER.error("抓取失败",e);
            }
            return new RecommendVo();
    }

    private String fetchCdnUrl(String rawText) {
        Pattern pattern = Pattern.compile("window\\.\\$avdt = (\\{.*?\\})\\s*</script>", Pattern.DOTALL);
        Matcher matcher = pattern.matcher(rawText);
        if (matcher.find()) {
            String jsonStr = matcher.group(1).replace("\\/", "/");
//            LOGGER.info("91----"+jsonStr);
            Map<String, Object> avdtData = JsonUtil.readValue(jsonStr, JsonUtil.getMapType(Object.class));
            if (avdtData != null) {
                @SuppressWarnings("unchecked")
                List<String> cdns = (List<String>) avdtData.get("cdns");
                Object hls = avdtData.get("hls");
                if (cdns != null && !cdns.isEmpty() && hls != null) {
                    return "https://" + cdns.get(0) + "/" + hls;
                }
            }
        } else {
            LOGGER.warn("未匹配到 window.$avdt 的数据内容");
        }
        return null;
    }

    private String fetch(String url){
        try {
//            String httpUrl= "104.160.191.19:5003/scrape?url="+ URLEncoder.encode(url);
//            return HttpCommonUtil.sendGet(httpUrl,"utf-8");
            ProcessBuilder processBuilder = new ProcessBuilder("curl", url);
            Process process = processBuilder.start();
            BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line).append("\n");
            }
            process.waitFor();
            return sb.toString();
        } catch (Exception e) {
            LOGGER.error("fetch error url={}",url,e);
            return null;
        }
    }
    public static String extractVideoUrlFromIframe(String iframeHtml) {
        // 正则表达式：匹配 videoUrl= 后面到 & 符号前的内容（非贪婪匹配）
        String regex = "videoUrl=(https?://[^&]+)";
        Pattern pattern = Pattern.compile(regex);
        Matcher matcher = pattern.matcher(iframeHtml);

        // 找到匹配的地址并返回
        if (matcher.find()) {
            return matcher.group(1);
        }
        return null; // 未找到视频地址时返回 null
    }

    // 测试代码
    public static void main(String[] args) {
        // 传入 iframe 标签字符串
        String iframeHtml = "<iframe src=\"https://cloud.hdcdn.online/LivePlayer.html?videoUrl=https://cdn1.hdcdn.online/1761478409/DVzEsCgl-sqEEdKf0XhonA/hls/874162/index.m3u8&autoplay=yes&muted=no&&poster=https://img.ml0987.com/thumb/874162.webp&aspect=16x9&live=false\" frameborder=\"0\" allowfullscreen></iframe>";

        // 提取并打印视频地址
        String videoUrl = extractVideoUrlFromIframe(iframeHtml);
        System.out.println("提取到的视频地址：" + videoUrl);
    }
}

