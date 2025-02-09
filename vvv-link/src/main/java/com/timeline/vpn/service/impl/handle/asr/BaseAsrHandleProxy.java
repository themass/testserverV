package com.timeline.vpn.service.impl.handle.asr;

import com.timeline.vpn.Constant;
import com.timeline.vpn.common.utils.Base64Util;
import com.timeline.vpn.model.chat.LlmRecord;
import com.timeline.vpn.model.chat.UserRole;
import com.timeline.vpn.model.form.AsrContentForm;
import com.timeline.vpn.model.form.ChatContentForm;
import com.timeline.vpn.model.form.SimpleMessage;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.AsrResponseVo;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.service.CacheRedisUtil;
import com.timeline.vpn.util.JsonUtil;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

/**
 * @author gqli
 * @version V1.0
 * @date 2017年11月28日 下午6:32:52
 */
public abstract class BaseAsrHandleProxy extends BaseAsrHandle {
    protected static final Logger LOGGER =
            LoggerFactory.getLogger(BaseAsrHandleProxy.class);

    @Override
    public AsrResponseVo asrHandlerBase(BaseQuery baseQuery, AsrContentForm chatContentForm) throws Exception{
        saveAudio(baseQuery, chatContentForm.getContent());
        AsrResponseVo asrResponseVo = asrHandler(baseQuery, chatContentForm);
        asrResponseVo.setId(chatContentForm.getId());
        asrResponseVo.setLang(baseQuery.getAppInfo().getLang());
        return asrResponseVo;
    }
    public abstract AsrResponseVo asrHandler(BaseQuery baseQuery, AsrContentForm chatContentForm) throws Exception;
    @Override
    public boolean isDefault() {
        return false;
    }
    public static void saveAudio(BaseQuery baseQuery, String audio) {
        try {
            String fileName = baseQuery.getUser().getName() + "_" + UUID.randomUUID() + ".wav" ;
            Path filePath = Paths.get(Constant.UPLOAD_DIR, fileName);
            // 创建上传目录（如果不存在）
            File uploadDir = new File(Constant.UPLOAD_DIR);
            if (!uploadDir.exists()) {
                uploadDir.mkdirs();
            }
            // 将上传的图片保存到指定路径
            Files.write(filePath, Base64Util.decodeBase64(audio)); // 写入数据
        } catch (Exception e) {
            LOGGER.error("", e);
        }
    }

}

