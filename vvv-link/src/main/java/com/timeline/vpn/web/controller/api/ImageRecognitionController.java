package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.ChatVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.service.impl.handle.picversion.VisionContext;
import com.timeline.vpn.util.JsonUtil;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;
import jakarta.validation.Valid;
import lombok.extern.slf4j.Slf4j;
import okhttp3.OkHttpClient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;


@RestController
@RequestMapping("/api/chat/ai")
@Slf4j
public class ImageRecognitionController extends BaseController {
    @Autowired
    private VisionContext visionContext;
    @PostMapping(value = "/recognize.json", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public JsonResult recognizeImage(@UserInfo BaseQuery baseQuery, @ModelAttribute @Valid ChatContentForm chatContent, @RequestParam("image") MultipartFile file) {
        log.info("请求参数"+JsonUtil.writeValueAsString(chatContent));
        Choice choice = visionContext.chatWithGpt(baseQuery, chatContent, file);
            return new JsonResult(choice);
    }

}