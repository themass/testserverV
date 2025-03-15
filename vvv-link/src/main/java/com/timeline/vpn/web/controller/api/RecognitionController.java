package com.timeline.vpn.web.controller.api;

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
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import static com.volcengine.model.maas.Base.form;


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
    public JsonResult file(@UserInfo BaseQuery baseQuery, @ModelAttribute @Valid ChatContentForm chatContent, @RequestParam("file") MultipartFile file) {
        log.info("file :"+form);
        BaseVisionHandleProxy.savePic(baseQuery,file);
        Choice choice = new Choice();
        choice.setId(chatContent.getId());
        Message message = new Message();
        message.setContent("hello!");
        message.setRole("assistant");
        choice.setMessage(message);
        return new JsonResult();
    }
}