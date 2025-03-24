package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.common.utils.HttpCommonUtil;
import com.timeline.vpn.model.chat.FileResponsVo;
import com.timeline.vpn.model.form.AsrContentForm;
import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.form.FeedbackContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.*;
import com.timeline.vpn.service.impl.handle.asr.AsrContext;
import com.timeline.vpn.service.impl.handle.picversion.BaseVisionHandleProxy;
import com.timeline.vpn.service.impl.handle.picversion.VisionContext;
import com.timeline.vpn.service.impl.handle.tts.TtsContext;
import com.timeline.vpn.util.JsonUtil;
import com.timeline.vpn.util.LaTeXFormulaReplacer;
import com.timeline.vpn.util.UnicodeToChinese;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.apache.hc.client5.http.impl.classic.CloseableHttpResponse;
import org.apache.hc.core5.http.ContentType;
import org.apache.hc.core5.http.HttpEntity;
import org.apache.hc.core5.http.io.entity.StringEntity;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.Map;


@RestController
@RequestMapping("/api/chat/ai")
@Slf4j
public class RecognitionController extends BaseController {
    @Autowired
    private VisionContext visionContext;
    @Autowired
    private AsrContext asrContext;
    @Autowired
    private TtsContext ttsContext;
    @PostMapping(value = "/recognize.json", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public JsonResult recognizeImage(@UserInfo BaseQuery baseQuery, @ModelAttribute @Valid ChatContentForm chatContent, @RequestParam("image") MultipartFile file) {
        log.info("请求参数"+JsonUtil.writeValueAsString(chatContent));
        Choice choice = visionContext.chatWithGpt(baseQuery, chatContent, file);
            return new JsonResult(choice);
    }
    @PostMapping(value = "/asr.json")
    public JsonResult recognizeVoice(@UserInfo BaseQuery baseQuery, @ModelAttribute @Valid AsrContentForm asrContentForm) {
        log.info("请求参数 :"+asrContentForm.getId()+";"+asrContentForm.getContent().length());
        AsrResponseVo asrResponseVo = asrContext.asrHandler(baseQuery, asrContentForm);
        return new JsonResult(asrResponseVo);
    }
    @PostMapping(value = "/tts.json")
    public JsonResult tts(@UserInfo BaseQuery baseQuery, @ModelAttribute @Valid AsrContentForm asrContentForm) {
        log.info("请求参数 :"+asrContentForm.getId()+";"+asrContentForm.getContent().length());
        TtsResponseVo ttsResponseVo = ttsContext.ttsHandler(baseQuery, asrContentForm);
        return new JsonResult(ttsResponseVo);
    }
    @PostMapping(value = "/feedback.json")
    public JsonResult feedback(@UserInfo BaseQuery baseQuery, @ModelAttribute @Valid FeedbackContentForm form) {
        log.info("用户反馈 :"+form);
        return new JsonResult();
    }
    @PostMapping(value = "/file.json")
    public JsonResult file(@UserInfo BaseQuery baseQuery, @ModelAttribute @Valid ChatContentForm chatContent, @RequestParam(value = "file") MultipartFile file) {
        try {
            BaseVisionHandleProxy.savePic(baseQuery, file);
            Choice choice = new Choice();
            choice.setId(chatContent.getId());
            Message message = new Message();
            message.setContent("hello!");
            message.setRole("assistant");
            choice.setMessage(message);

            // 调用上传文件的接口
            CloseableHttpResponse response = HttpCommonUtil.sendPostWithMultipartFile("http://127.0.0.1:5000/upload", file, null);
            try {
                String content = HttpCommonUtil.responseToString(response);
                log.info("Response from upload: {}", UnicodeToChinese.convertUnicode(content));
                FileResponsVo fileResponsVo = JsonUtil.readValue(content, FileResponsVo.class);
                // 处理响应内容
                // 例如，解析 JSON 响应并设置到 choice 中
                message.setContent(fileResponsVo.getSummary());
            } finally {
                response.close();
            }

            return new JsonResult(choice);
        } catch (Exception e) {
            log.error("Error processing file upload", e);
            return new JsonResult();
        }
    }
    @PostMapping(value = "/local/file.json")
    public JsonResult localFile(@UserInfo BaseQuery baseQuery, @ModelAttribute @Valid ChatContentForm chatContent, @RequestParam(value = "file") MultipartFile file) {
        try {
            String path = BaseVisionHandleProxy.savePic(baseQuery, file);
            Choice choice = new Choice();
            choice.setId(chatContent.getId());
            Message message = new Message();
            message.setContent("hello!");
            message.setRole("assistant");
            choice.setMessage(message);
            Map<String,String> hashMap = new HashMap<>();
            hashMap.put("path",path);
            HttpEntity entity = new StringEntity(JsonUtil.writeValueAsString(hashMap), ContentType.APPLICATION_JSON);
            // 调用上传文件的接口
            CloseableHttpResponse response = HttpCommonUtil.sendPostWithEntity("http://127.0.0.1:5000/upload1/file", entity, null);
            try {
                String content = HttpCommonUtil.responseToString(response);
                log.info("Response from upload: {}", UnicodeToChinese.convertUnicode(content));
                FileResponsVo fileResponsVo = JsonUtil.readValue(content, FileResponsVo.class);
                // 处理响应内容
                // 例如，解析 JSON 响应并设置到 choice 中
                message.setContent(fileResponsVo.getSummary());
            } finally {
                response.close();
            }

            return new JsonResult(choice);
        } catch (Exception e) {
            log.error("Error processing file upload", e);
            return new JsonResult();
        }
    }
    @PostMapping(value = "/local/ocr.json")
    public JsonResult localOcr(@UserInfo BaseQuery baseQuery, @ModelAttribute @Valid ChatContentForm chatContent, @RequestParam(value = "image") MultipartFile image) {
        try {
            String path = BaseVisionHandleProxy.savePic(baseQuery, image);
            Choice choice = new Choice();
            choice.setId(chatContent.getId());
            Message message = new Message();
            message.setContent("hello!");
            message.setRole("assistant");
            choice.setMessage(message);
            Map<String,String> hashMap = new HashMap<>();
            hashMap.put("path",path);
            HttpEntity entity = new StringEntity(JsonUtil.writeValueAsString(hashMap), ContentType.APPLICATION_JSON);
            // 调用上传文件的接口
            CloseableHttpResponse response = HttpCommonUtil.sendPostWithEntity("http://127.0.0.1:5000/upload1/ocr", entity, null);
            try {
                String content = HttpCommonUtil.responseToString(response);
                content = UnicodeToChinese.convertUnicode(content);
                log.info("Response from upload 原数据: {}", content);
                content = LaTeXFormulaReplacer.replaceBrackets(content);
                log.info("Response from upload 转换后: {}", content);
                FileResponsVo fileResponsVo = JsonUtil.readValue(content, FileResponsVo.class);
                // 处理响应内容
                // 例如，解析 JSON 响应并设置到 choice 中
                message.setContent(fileResponsVo.getSummary());
            } finally {
                response.close();
            }

            return new JsonResult(choice);
        } catch (Exception e) {
            log.error("Error processing file upload", e);
            return new JsonResult();
        }
    }

    public static void main(String[] args) throws Exception {
//        Map<String,String> hashMap = new HashMap<>();
//        hashMap.put("path","/Users/liguoqing/Downloads/使用说明（必读）.pdf");
//        HttpEntity entity = new FileEntity(new File("/Users/liguoqing/Downloads/使用说明（必读）.pdf"), ContentType.APPLICATION_JSON);
//        Map<String,String> header = new HashMap<>();
//        header.put("devid","111d");
//        header.put("Vpn-Token","111d");
//        header.put("user-agent","Dalvik/2.1.0 (Linux; U; Android 12; ADY-AL00 Build/HUAWEIADY-AL00)VVVB/1.1.0.33,channel=null,cpu=[arm64-v8a, armeabi-v7a, armeabi],Webkit/null,IE17395370923543247c8cf9796f5e786cdb66e256a5f9e");
//        CloseableHttpResponse response = HttpCommonUtil.sendPostWithEntity("http://127.0.0.1:8888/api/chat/ai/local/ocr.json", entity, header);
//            String content = HttpCommonUtil.responseToString(response);
//        System.out.println(UnicodeToChinese.convertUnicode(content));
//            log.info("Response from upload: {}", UnicodeToChinese.convertUnicode(content));
        String t = "{\n" +
                "  \"filename\": \"/home/web/webroot/files/themass_c434b920-7be8-4332-a36a-4c46c12e26b3_IMG_20250320_011338.webp\",\n" +
                "  \"summary\": \"### 练习1\\n\\n#### (1) 经过多久后两人第一次相遇？\\n\\n设两人第一次相遇所需时间为 $ t $ 秒。由于大强和小强背向而行，他们的相对速度是他们速度的和，即 $ 6 \\\\text{ 米/秒} + 4 \\\\text{ 米/秒} = 10 \\\\text{ 米/秒} $。他们相遇时，两人共同跑过的距离等于跑道的周长，即200米。因此，我们有方程：\\n\\n$$ 10t = 200 $$\\n\\n解得：\\n\\n$$ t = \\\\frac{200}{10} = 20 \\\\text{ 秒} $$\\n\\n#### (2) 再经过多久两人第二次相遇？\\n\\n两人第一次相遇后，他们继续背向而行，再次相遇时，他们共同跑过的距离又是一个跑道的周长，即200米。由于他们的相对速度仍然是10米/秒，我们有：\\n\\n$$ 10t' = 200 $$\\n\\n其中 $ t' $ 是从第一次相遇后到第二次相遇所需的时间。解得：\\n\\n$$ t' = \\\\frac{200}{10} = 20 \\\\text{ 秒} $$\\n\\n### 练习2\\n\\n甲、乙两人每跑5秒，都要停10秒休息，所以他们的实际运动周期是15秒。在每个周期内，甲跑的距离是 $ 10 \\\\times 5 = 50 $ 米，乙跑的距离是 $ 5 \\\\times 5 = 25 $ 米。两人每周期共同跑过的距离是 $ 50 + 25 = 75 $ 米。\\n\\n设两人第一次相遇所需周期数为 $ n $。由于A、B两点相距100米，两人相遇时，他们共同跑过的距离加上A、B两点之间的距离应该等于跑道的周长，即400米。因此，我们有方程：\\n\\n$$ 75n + 100 = 400 $$\\n\\n解得：\\n\\n$$ 75n = 300 $$\\n$$ n = \\\\frac{300}{75} = 4 $$\\n\\n所以，甲、乙两人需要4个周期才能第一次相遇。每个周期是15秒，所以总时间是：\\n\\n$$ 4 \\\\times 15 = 60 \\\\text{ 秒} $$\"\n" +
                "}";
        FileResponsVo fileResponsVo = JsonUtil.readValue(t, FileResponsVo.class);
        System.out.println(fileResponsVo);
    }
}