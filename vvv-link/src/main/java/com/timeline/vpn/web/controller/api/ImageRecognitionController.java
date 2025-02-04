package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.UUID;

@RestController
@RequestMapping("/api/chat/ai")
@Slf4j
public class ImageRecognitionController extends BaseController {

    private static final String UPLOAD_DIR = "/home/web/webroot/files";
    @PostMapping(value = "/recognize.json", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public JsonResult recognizeImage(@UserInfo BaseQuery baseQuery, @RequestParam("image") MultipartFile file) {
        try {
            // 保存上传的图片到临时文件
            String fileName = baseQuery.getUser().getName()+"_"+ UUID.randomUUID()+"_" +file.getOriginalFilename();
            Path filePath = Paths.get(UPLOAD_DIR, fileName);
            // 创建上传目录（如果不存在）
            File uploadDir = new File(UPLOAD_DIR);
            if (!uploadDir.exists()) {
                uploadDir.mkdirs();
            }
            // 将上传的图片保存到指定路径
            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);
            return new JsonResult();
        } catch (IOException e) {
           log.error("",e);
        }
        return new JsonResult();

    }
}