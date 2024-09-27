package com.timeline.vpn.service;

import com.timeline.vpn.common.utils.JacksonJsonUtil;
import com.timeline.vpn.common.utils.SpringUtils;
import com.timeline.vpn.model.chat.LlmRecord;
import com.timeline.vpn.model.chat.UserRole;
import com.timeline.vpn.model.param.BaseQuery;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;
import org.apache.commons.lang3.StringUtils;
import org.springframework.data.redis.core.StringRedisTemplate;

import java.util.List;
import java.util.stream.Collectors;

/**
 * @Author： liguoqing
 * @Date： 2024/9/27 11:14
 * @Describe：
 */
public class CacheRedisUtil {
    private static StringRedisTemplate stringRedisTemplate = SpringUtils.getStringRedisTemplate();
    private static String CHAT_HISTORY = "chat_record_%s";
    public static void appendRecod(BaseQuery baseQuery, LlmRecord record){
        if(StringUtils.isBlank(record.getText())){
            return;
        }
        String chatHistory = String.format(CHAT_HISTORY, baseQuery.getUser().getId());
        stringRedisTemplate.opsForList().rightPush(chatHistory, JacksonJsonUtil.toJsonStr(record));
    }
    public static List<LlmRecord> getRecod(BaseQuery baseQuery, long sessionId){
        String chatHistory = String.format(CHAT_HISTORY, baseQuery.getUser().getId());
        return stringRedisTemplate.opsForList().range(chatHistory,-20,-1).stream().map(o -> JacksonJsonUtil.readValue(o, LlmRecord.class)).filter(o -> o.getSessionId() == sessionId).collect(Collectors.toList());
    }

}
