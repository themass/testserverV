package com.timeline.vpn.web.controller.api;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.timeline.vpn.model.chat.ChatPicMessages;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.ChatVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.util.JsonUtil;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;
import lombok.extern.slf4j.Slf4j;
import okhttp3.OkHttpClient;
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
import java.util.*;
import java.util.concurrent.TimeUnit;

@RestController
@RequestMapping("/api/ai")
@Slf4j
public class ImageRecognitionController extends BaseController {

    private static final String UPLOAD_DIR = "/home/web/webroot/files";
    public static OkHttpClient.Builder builder = new OkHttpClient.Builder();
    public static okhttp3.OkHttpClient httpClient;
    static {
        // 设置超时时间
        builder.connectTimeout(60, TimeUnit.SECONDS);  // 连接超时
        builder.readTimeout(60, TimeUnit.SECONDS);     // 读取超时
        builder.writeTimeout(60, TimeUnit.SECONDS);    // 写入超时
        // 设置长连接保持
        int maxIdleConnections = 15; // 最大空闲连接数
        long keepAliveDuration = 30; // 最大空闲时间（秒）
        builder.connectionPool(new okhttp3.ConnectionPool(maxIdleConnections, keepAliveDuration, TimeUnit.SECONDS));
        httpClient = builder.build();
    }
    @PostMapping(value = "/recognize.json", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public JsonResult recognizeImage(@UserInfo BaseQuery baseQuery, @RequestParam("image") MultipartFile file) {
            Choice choice = process(file.getOriginalFilename(), file);
            savePic(baseQuery, file);
            return new JsonResult(choice);
    }
    private void savePic(BaseQuery baseQuery, MultipartFile file){
        try {
            String fileName = baseQuery.getUser().getName() + "_" + UUID.randomUUID() + "_" + file.getOriginalFilename();
            Path filePath = Paths.get(UPLOAD_DIR, fileName);
            // 创建上传目录（如果不存在）
            File uploadDir = new File(UPLOAD_DIR);
            if (!uploadDir.exists()) {
                uploadDir.mkdirs();
            }
            // 将上传的图片保存到指定路径
            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);
        }catch (Exception e){
            log.error("", e);
        }
    }
    private Choice process(String imagePath, MultipartFile file){
        try {
            // 读取文件内容到字节数组
            byte[] imageBytes = file.getBytes();

            // 使用Base64编码字节数组
            String base64EncodedImage = Base64.getEncoder().encodeToString(imageBytes);

            // 获取文件扩展名
            String fileExtension = getFileExtension(imagePath);

            // 构建data:image URL
            String imageUrlData = "data:image/" + fileExtension + ";base64," + base64EncodedImage;

            // 构建请求消息
            List<Map<String, Object>> messages = new ArrayList<>();

            // 系统消息
            Map<String, Object> systemMessage = new HashMap<>();
            systemMessage.put("role", "system");
            systemMessage.put("content", "你是 Kimi。");
            messages.add(systemMessage);

            // 用户消息
            Map<String, Object> userMessage = new HashMap<>();
            userMessage.put("role", "user");

            List<Map<String, Object>> userContent = new ArrayList<>();

            // 图片部分
            Map<String, Object> imagePart = new HashMap<>();
            imagePart.put("type", "image_url");
            Map<String, String> imageUrlMap = new HashMap<>();
            imageUrlMap.put("url", imageUrlData);
            imagePart.put("image_url", imageUrlMap);
            userContent.add(imagePart);

            // 文字部分
            Map<String, Object> textPart = new HashMap<>();
            textPart.put("type", "text");
            textPart.put("text", "请描述图片的内容。");
            userContent.add(textPart);

            userMessage.put("content", userContent);
            messages.add(userMessage);

            ChatPicMessages picMessages = new ChatPicMessages();
            picMessages.setMessages(messages);
            picMessages.setModel("moonshot-v1-8k-vision-preview");

            okhttp3.MediaType mediaType = okhttp3.MediaType.parse("application/json");
            okhttp3.RequestBody body = okhttp3.RequestBody.create(mediaType, JsonUtil.writeValueAsString(picMessages));
            okhttp3.Request httpRequest = new okhttp3.Request.Builder()
                    .url("https://api.moonshot.cn/v1/chat/completions")
                    .addHeader("Authorization", "Bearer sk-it18PatDDjE3U68z1qsOrkeybU9YZRxr6hW5vqZfirRiFUlS")
                    .addHeader("stream", "false")
                    .post(body)
                    .build();
            okhttp3.Response response = httpClient.newCall(httpRequest).execute();
            String res = response.body().string();
            log.info(res);
            ChatVo vo = JsonUtil.readValue(res,ChatVo.class);
            if(vo.getChoices()!=null&&vo.getChoices().size()>0){
                Choice choice =  vo.getChoices().get(0);
                return choice;
            }
        } catch (IOException e) {
            log.error("",e);
        }
        return null;
    }
    // 获取文件扩展名的方法
    private static String getFileExtension(String fileName) {
        if (fileName.lastIndexOf(".") != -1 && fileName.lastIndexOf(".") != 0) {
            return fileName.substring(fileName.lastIndexOf(".") + 1);
        }
        return ""; // 没有扩展名
    }
}