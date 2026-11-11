package com.timeline.vpn.photosolve;

import com.fasterxml.jackson.databind.DeserializationFeature;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.timeline.vpn.exception.ApiException;
import com.timeline.vpn.photosolve.model.PhotoSolveErrno;
import com.timeline.vpn.photosolve.model.PhotoSolveResponse;
import com.volcengine.ark.runtime.model.completion.chat.ChatCompletionContentPart;
import com.volcengine.ark.runtime.model.completion.chat.ChatCompletionRequest;
import com.volcengine.ark.runtime.model.completion.chat.ChatCompletionResult;
import com.volcengine.ark.runtime.model.completion.chat.ChatMessage;
import com.volcengine.ark.runtime.model.completion.chat.ChatMessageRole;
import com.volcengine.ark.runtime.service.ArkService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Base64;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

/**
 * 豆包（火山方舟）视觉模型实现。
 *
 * 复用项目里已有的 {@code volcengine-java-sdk-ark-runtime}（vvv-common 已声明），
 * 不走 OpenAI 兼容 REST：SDK 已经处理好鉴权头、重试和响应结构，也让豆包/其它方舟模型换接入点
 * 时只改配置。
 *
 * 关键设计：
 * - **图片走 base64 data URL**：一张图最多 5MB，最多 4 张，请求体可控；也避免服务端再落一份原图。
 * - **超时由 futures 控制**：ArkService 的同步调用没有超时参数，这里把调用丢到线程池并用
 *   {@code get(timeout)} 限时，超时返回 50001（客户端可重试），不会把 Tomcat 线程一直占着。
 * - **解析容错**：模型偶尔会返回```json 包裹的内容或前后有说明文字，{@link #extractJson} 负责抠出
 *   JSON；仍然失败时把原始文本作为「解析失败」返回，而不是让整个请求 500。
 */
@Slf4j
@Component
public class DoubaoPhotoSolveProvider implements PhotoSolveProvider {

    private static final ObjectMapper MAPPER = new ObjectMapper()
            .configure(DeserializationFeature.FAIL_ON_UNKNOWN_PROPERTIES, false);

    /** 图像理解用视觉接入点；模型名里带 vision 或在配置里指定，具体值由部署方填。 */
    private volatile ArkService service;

    @Override
    public String name() {
        return PhotoSolveConfig.model();
    }

    @Override
    public boolean isAvailable() {
        return PhotoSolveConfig.isConfigured();
    }

    @Override
    public PhotoSolveResponse solve(List<byte[]> images, List<String> mimeTypes, String text,
                                    String subject, String grade, String requestId) {
        PhotoSolveConfig.requireConfigured();
        if (images == null || images.isEmpty()) {
            throw new ApiException(PhotoSolveErrno.BAD_REQUEST, PhotoSolveErrno.messageOf(PhotoSolveErrno.BAD_REQUEST));
        }

        List<ChatMessage> messages = new ArrayList<>();
        messages.add(ChatMessage.builder()
                .role(ChatMessageRole.SYSTEM)
                .content(PhotoSolvePrompt.SYSTEM)
                .build());

        List<ChatCompletionContentPart> parts = new ArrayList<>();
        for (int i = 0; i < images.size(); i++) {
            String mime = mimeTypes != null && i < mimeTypes.size() ? mimeTypes.get(i) : "image/jpeg";
            String dataUrl = "data:" + mime + ";base64," + Base64.getEncoder().encodeToString(images.get(i));
            parts.add(ChatCompletionContentPart.builder()
                    .type("image_url")
                    .imageUrl(new ChatCompletionContentPart.ChatCompletionContentPartImageURL(dataUrl))
                    .build());
        }
        parts.add(ChatCompletionContentPart.builder()
                .type("text")
                .text(PhotoSolvePrompt.user(text, subject, grade))
                .build());
        messages.add(ChatMessage.builder()
                .role(ChatMessageRole.USER)
                .multiContent(parts)
                .build());

        ChatCompletionRequest request = ChatCompletionRequest.builder()
                .model(PhotoSolveConfig.model())
                .messages(messages)
                // 温度低一点：解题要稳定，不要花式发挥
                .temperature(0.2)
                .maxTokens(4096)
                .build();

        String raw = callWithTimeout(request, requestId);
        return parse(raw, requestId);
    }

    /** 调模型并限时。超时/异常都转成对客户端有意义的错误码。 */
    private String callWithTimeout(ChatCompletionRequest request, String requestId) {
        int timeout = PhotoSolveConfig.timeoutSeconds();
        CompletableFuture<String> future = CompletableFuture.supplyAsync(() -> {
            ChatCompletionResult result = service().createChatCompletion(request);
            if (result == null || result.getChoices() == null || result.getChoices().isEmpty()) {
                throw new IllegalStateException("empty completion choices");
            }
            Object content = result.getChoices().get(0).getMessage().getContent();
            return content == null ? "" : content.toString();
        });
        try {
            return future.get(timeout, TimeUnit.SECONDS);
        } catch (TimeoutException e) {
            future.cancel(true);
            log.warn("photosolve {} model timeout after {}s", requestId, timeout);
            throw new ApiException(PhotoSolveErrno.MODEL_FAILED, PhotoSolveErrno.messageOf(PhotoSolveErrno.MODEL_FAILED));
        } catch (ExecutionException e) {
            log.error("photosolve {} model call failed", requestId, e.getCause());
            throw new ApiException(PhotoSolveErrno.MODEL_FAILED, PhotoSolveErrno.messageOf(PhotoSolveErrno.MODEL_FAILED));
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new ApiException(PhotoSolveErrno.MODEL_FAILED, PhotoSolveErrno.messageOf(PhotoSolveErrno.MODEL_FAILED));
        }
    }

    private ArkService service() {
        ArkService local = service;
        if (local == null) {
            synchronized (this) {
                local = service;
                if (local == null) {
                    local = ArkService.builder()
                            .apiKey(PhotoSolveConfig.apiKey())
                            .baseUrl(PhotoSolveConfig.endpoint())
                            .build();
                    service = local;
                }
            }
        }
        return local;
    }

    /**
     * 把模型输出解析成 {@link PhotoSolveResponse}。
     *
     * 兜底策略：JSON 解析失败时，把整段文本当作「题干 + 答案」放进一条 question，
     * questionFound 保持 true（至少让用户看到模型的输出），并在日志里记录原始响应。
     * 这样模型偶发不听话不会变成对用户来说的「服务失败」。
     */
    PhotoSolveResponse parse(String raw, String requestId) {
        PhotoSolveResponse response = new PhotoSolveResponse();
        response.setRequestId(requestId);
        response.setProviderUsed(name());

        String json = extractJson(raw);
        if (json == null) {
            log.warn("photosolve {} response is not JSON: {}", requestId, abbreviate(raw));
            response.setQuestionFound(false);
            return response;
        }
        try {
            JsonNode root = MAPPER.readTree(json);
            boolean found = root.path("questionFound").asBoolean(true);
            response.setQuestionFound(found);
            response.setSubject(root.path("subject").asText(""));
            JsonNode questions = root.path("questions");
            if (questions.isArray()) {
                for (JsonNode q : questions) {
                    response.getQuestions().add(toQuestion(q, response.getQuestions().size() + 1));
                }
            }
            if (!found) {
                response.getQuestions().clear();
            }
            return response;
        } catch (Exception e) {
            log.warn("photosolve {} JSON parse failed, using fallback text", requestId, e);
            PhotoSolveResponse.Question q = new PhotoSolveResponse.Question();
            q.setIndex(1);
            q.setText(raw == null ? "" : raw.trim());
            q.setFinalAnswer("");
            response.setQuestionFound(true);
            response.getQuestions().add(q);
            return response;
        }
    }

    private PhotoSolveResponse.Question toQuestion(JsonNode node, int fallbackIndex) {
        PhotoSolveResponse.Question q = new PhotoSolveResponse.Question();
        q.setIndex(node.path("index").asInt(fallbackIndex));
        q.setText(node.path("text").asText(""));
        q.setLatex(node.path("latex").asText(""));
        q.setFinalAnswer(node.path("finalAnswer").asText(""));
        q.setFinalAnswerLatex(node.path("finalAnswerLatex").asText(""));
        JsonNode steps = node.path("steps");
        if (steps.isArray()) {
            for (JsonNode s : steps) {
                PhotoSolveResponse.Step step = new PhotoSolveResponse.Step();
                step.setIndex(s.path("index").asInt(q.getSteps().size() + 1));
                step.setText(s.path("text").asText(""));
                step.setLatex(s.path("latex").asText(""));
                q.getSteps().add(step);
            }
        }
        if (node.hasNonNull("confidence")) {
            q.setConfidence(node.path("confidence").asDouble());
        }
        return q;
    }

    /** 从可能带 ```json 围栏或前后说明的文本里抠出第一个完整的 JSON 对象。 */
    static String extractJson(String raw) {
        if (raw == null) {
            return null;
        }
        String text = raw.trim();
        int fence = text.indexOf("```");
        if (fence >= 0) {
            int start = text.indexOf('\n', fence);
            int end = text.indexOf("```", fence + 3);
            if (start > 0 && end > start) {
                text = text.substring(start + 1, end).trim();
            }
        }
        int begin = text.indexOf('{');
        if (begin < 0) {
            return null;
        }
        // 括号配平，跳过字符串里的括号
        int depth = 0;
        boolean inString = false;
        boolean escaped = false;
        for (int i = begin; i < text.length(); i++) {
            char c = text.charAt(i);
            if (inString) {
                if (escaped) {
                    escaped = false;
                } else if (c == '\\') {
                    escaped = true;
                } else if (c == '"') {
                    inString = false;
                }
                continue;
            }
            if (c == '"') {
                inString = true;
            } else if (c == '{') {
                depth++;
            } else if (c == '}') {
                depth--;
                if (depth == 0) {
                    return text.substring(begin, i + 1);
                }
            }
        }
        return null;
    }

    private static String abbreviate(String text) {
        if (text == null) {
            return "null";
        }
        return text.length() <= 500 ? text : text.substring(0, 500) + "...";
    }
}
