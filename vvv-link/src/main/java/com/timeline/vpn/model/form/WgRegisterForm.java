package com.timeline.vpn.model.form;

import com.timeline.vpn.Constant;
import lombok.Data;
import lombok.ToString;
import org.hibernate.validator.constraints.NotBlank;

/**
 * WireGuard 设备公钥注册表单。
 * <p>
 * 对应接口 {@code POST /api/host/wg/register.json}，与 Android 端
 * {@code WireGuardRegistrationUtil} 提交的字段一致。
 *
 * @author gqli
 * @date 2026年11月1日
 * @version V1.0
 */
@ToString
@Data
public class WgRegisterForm {
    /** 设备标识；留空时服务端回退到请求头里的设备号。 */
    private String deviceId;
    @NotBlank(message = Constant.ResultMsg.RESULT_DATA_EMPETY_ERROR)
    private String publicKey;
}
