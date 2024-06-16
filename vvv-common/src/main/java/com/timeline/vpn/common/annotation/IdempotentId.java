package com.timeline.vpn.common.annotation;

import java.lang.annotation.*;

/**
 * 幂等id，跟@Idempotent配合使用，作为redis缓存key的后缀
 *
 * @Author xudongchang
 * @Date 2023/12/13
 */
@Target(ElementType.PARAMETER)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface IdempotentId {
}
