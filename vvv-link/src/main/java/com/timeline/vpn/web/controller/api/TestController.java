package com.timeline.vpn.web.controller.api;

import cn.hutool.log.Log;
import com.timeline.vpn.common.utils.Base64Util;
import com.timeline.vpn.model.form.AsrContentForm;
import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.AsrResponseVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.model.vo.TtsResponseVo;
import com.timeline.vpn.service.impl.handle.asr.AsrContext;
import com.timeline.vpn.service.impl.handle.chat.*;
import com.timeline.vpn.service.impl.handle.tts.AliTtsServiceImpl;
import com.timeline.vpn.service.impl.handle.tts.TtsContext;
import com.timeline.vpn.test.java.demo.TtsVolcResponse;
import com.timeline.vpn.util.JsonUtil;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.*;

/**
 * @author gqli
 * @date 2015年7月24日 下午3:16:25
 * @version V1.0
 */
@RestController
@RequestMapping("/api/test")
@Slf4j
public class TestController extends BaseController {
    @Autowired
    private ChatDeepseekHandler chatDeepseekHandler;
    @Autowired
    private ChatDoubaoHandler chatDoubaoHandler;
    @Autowired
    private ChatGeminiHandler chatGeminiHandler;
    @Autowired
    private List<BaseChatHandleProxy> list;
    @Autowired
    private AsrContext asrContext;
    @Autowired
    private TtsContext ttsContext;
    @Autowired
    private AliTtsServiceImpl aliTtsService;
    @RequestMapping(value = "/test.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult recommendList(@UserInfo BaseQuery baseQuery) {
        Map<String, String> map = new HashMap<>();
        map.put("key", "test");
        return new JsonResult(map);
    }
    @RequestMapping(value = "/testmychat.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult testmychat(@UserInfo BaseQuery baseQuery, @RequestParam(name = "content") String content) throws Exception {
        List<Choice> listC = new ArrayList<>();
        ChatContentForm chatContentForm = new ChatContentForm();
        chatContentForm.setContent(content);
        chatContentForm.setId("1111");
        list.stream().forEach(o -> {
            try {
                Choice  choice = o.chatWithGptBase(baseQuery, chatContentForm);
                listC.add(choice);
                log.info("实例="+o.getClass().getSimpleName()+" ;content="+ JsonUtil.writeValueAsString(choice));
            } catch (Exception e) {
                log.error("实例="+o.getClass().getSimpleName(),e);
            }

        });
//        Choice choice = chatDeepseekHandler.chatWithGpt(baseQuery, content);
//        log.info("kimi="+ JsonUtil.writeValueAsString(choice));
//        choice = chatDoubaoHandler.chatWithGpt(baseQuery, content);
//        log.info("doubao="+ JsonUtil.writeValueAsString(choice));
        return new JsonResult(listC);
    }
    @RequestMapping(value = "/testasr.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult testAsr(@UserInfo BaseQuery baseQuery, @RequestParam String path) throws Exception {
        String filePath = "/Users/liguoqing/Downloads/test/voice_1739113889844.wav"; // 定义文件路径
        byte[] data = new byte[0];
        try (FileInputStream fis = new FileInputStream(path)) {
            data = new byte[fis.available()]; // 创建一个足够大的字节数组
            fis.read(data); // 读取文件内容到字节数组
        } catch (IOException e) {
            e.printStackTrace(); // 打印异常信息
        }
        AsrContentForm asrContentForm = new AsrContentForm();
        asrContentForm.setId("111");
        asrContentForm.setContent(Base64Util.encodeBase64(data));
        AsrResponseVo asrResponseVo = asrContext.asrHandler(baseQuery, asrContentForm);
        return new JsonResult(asrResponseVo);
    }
    @RequestMapping(value = "/testtts.json")
    public JsonResult tts(@UserInfo BaseQuery baseQuery, @ModelAttribute @Valid AsrContentForm asrContentForm) {
        log.info("请求参数 :"+asrContentForm.getId()+";"+asrContentForm.getContent().length());
        TtsResponseVo ttsResponseVo = aliTtsService.textToVideo(baseQuery, asrContentForm);
        String filePath = "/Users/gqli/Downloads/test/example.mp3";
        try (FileOutputStream fos = new FileOutputStream(filePath)) {
            fos.write(Base64Util.decodeBase64(ttsResponseVo.getData())); // 写入数据
            System.out.println("Data written to file successfully.");
        } catch (IOException e) {
            e.printStackTrace(); // 打印异常信息
        }
        return new JsonResult(ttsResponseVo);
    }
}

