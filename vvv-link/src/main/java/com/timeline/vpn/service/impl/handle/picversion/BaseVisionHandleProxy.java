package com.timeline.vpn.service.impl.handle.picversion;

import com.timeline.vpn.Constant;
import com.timeline.vpn.model.chat.ChatPicMessages;
import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.ChatVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.util.JsonUtil;
import lombok.extern.slf4j.Slf4j;
import okhttp3.OkHttpClient;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.*;
import java.util.concurrent.TimeUnit;

/**
 * @author gqli
 * @version V1.0
 * @date 2017年11月28日 下午6:32:52
 */
@Slf4j
public abstract class BaseVisionHandleProxy extends BaseVisionHandle {
    protected static final Logger LOGGER =
            LoggerFactory.getLogger(BaseVisionHandleProxy.class);


    static OkHttpClient.Builder builder = new OkHttpClient.Builder();
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
    private String zhText = "请根据以下要求描述图片内容：\n" +
            "\n" +
            "**任务要求**：\n" +
            "1. **内容描述**：详细描述图片中的内容，包括主要元素、场景、色彩、布局等，确保描述清晰、准确且完整。\n" +
            "2. **格式规范**：\n" +
            "   - 使用标准 Markdown 格式返回描述内容。\n" +
            "   - 描述中避免使用非标准格式（如代码块、HTML 标签等）。\n" +
            "   - 如果描述中包含数学公式，请使用 `$$...$$` 包裹的完整 LaTeX 表达式。\n" +
            "   - 不要添加任何无关内容，如“用 Markdown 格式表示如下”或“```markdown```”等。\n" +
            "3. **语言风格**：\n" +
            "   - 描述应简洁明了，避免冗余。\n" +
            "   - 使用自然语言，确保描述通顺易懂。";
    private String enText = "Please describe the content of the image according to the following requirements:\n" +
            "\n" +
            "**Task Requirements**:\n" +
            "1. **Content Description**:\n" +
            "   - Provide a detailed description of the image, including the main elements, scene, colors, layout, etc. Ensure that the description is clear, accurate, and comprehensive.\n" +
            "2. **Format Specifications**:\n" +
            "   - Return the description in standard Markdown format.\n" +
            "   - Avoid using non-standard formats (such as code blocks, HTML tags, etc.).\n" +
            "   - If the description includes mathematical formulas, use `$$...$$` to enclose complete LaTeX expressions.\n" +
            "   - Do not include any irrelevant content, such as \"Displayed in Markdown format below\" or \"```markdown```\".\n" +
            "3. **Language Style**:\n" +
            "   - The description should be concise and clear, avoiding redundancy.\n" +
            "   - Use natural language to ensure the description is smooth and understandable.";

    public Choice chatWithGptBase(BaseQuery baseQuery, ChatContentForm chatContentForm, MultipartFile file) throws Exception {
        savePic(baseQuery, file);
        String text = Constant.LANG_ZH.equals(baseQuery.getAppInfo().getLang())?zhText:enText;
        return chatWithGpt(baseQuery, chatContentForm, file, text);
    }

    public abstract Choice chatWithGpt(BaseQuery baseQuery, ChatContentForm chatContentForm, MultipartFile file, String text) throws Exception;

    @Override
    public boolean isDefault() {
        return false;
    }

    public static String savePic(BaseQuery baseQuery, MultipartFile file) {
        try {
            String fileName = baseQuery.getUser().getName() + "_" + UUID.randomUUID() + "_" + file.getOriginalFilename();
            Path filePath = Paths.get(Constant.UPLOAD_DIR, fileName);
            // 创建上传目录（如果不存在）
            File uploadDir = new File(Constant.UPLOAD_DIR);
            if (!uploadDir.exists()) {
                uploadDir.mkdirs();
            }
            // 将上传的图片保存到指定路径
            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);
            log.info("save file:"+fileName);
            return Constant.UPLOAD_DIR+"/"+ fileName;
        } catch (Exception e) {
            log.error("", e);
        }
        return null;
    }

    public ChatPicMessages getChatPicMessages(MultipartFile file, String modle, String text) {
        try {
            // 读取文件内容到字节数组
            byte[] imageBytes = file.getBytes();
            // 使用Base64编码字节数组
            String base64EncodedImage = Base64.getEncoder().encodeToString(imageBytes);
            // 获取文件扩展名
            String fileExtension = getFileExtension(file.getOriginalFilename());
            // 构建data:image URL
            String imageUrlData = "data:image/" + fileExtension + ";base64," + base64EncodedImage;
            // 构建请求消息
            List<Map<String, Object>> messages = new ArrayList<>();

            // 系统消息
            Map<String, Object> systemMessage = new HashMap<>();
            systemMessage.put("role", "system");
            systemMessage.put("content", "你是一个智能AI小助手");
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
            textPart.put("text", text);
            userContent.add(textPart);

            userMessage.put("content", userContent);
            messages.add(userMessage);
            ChatPicMessages picMessages = new ChatPicMessages();
            picMessages.setMessages(messages);
            picMessages.setModel(modle);
            return picMessages;
        }catch (Exception e){
            return null;
        }

    }
    public Choice process(ChatPicMessages picMessages, String url, String key) {
            try{
                okhttp3.MediaType mediaType = okhttp3.MediaType.parse("application/json");
                okhttp3.RequestBody body = okhttp3.RequestBody.create(mediaType, JsonUtil.writeValueAsString(picMessages));
                okhttp3.Request httpRequest = new okhttp3.Request.Builder()
                        .url(url)
                        .addHeader("Authorization", key)
                        .addHeader("stream", "false")
                        .post(body)
                        .build();
                okhttp3.Response response = httpClient.newCall(httpRequest).execute();
                String res = response.body().string();
                log.info(res);
                ChatVo vo = JsonUtil.readValue(res, ChatVo.class);
                if (vo.getChoices() != null && vo.getChoices().size() > 0) {
                    Choice choice = vo.getChoices().get(0);
                    return choice;
                }
            } catch (IOException e) {
                log.error("", e);
            }
        return new Choice();
    }

        // 获取文件扩展名的方法
    public static String getFileExtension(String fileName) {
        if (fileName.lastIndexOf(".") != -1 && fileName.lastIndexOf(".") != 0) {
            return fileName.substring(fileName.lastIndexOf(".") + 1);
        }
        return ""; // 没有扩展名
    }

}

