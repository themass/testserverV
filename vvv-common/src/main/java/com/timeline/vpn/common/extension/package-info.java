/**
 * 扩展点机制
 * - @Extensible：接口注解
 * - path: 类似url，定义路径
 * - @Extension：实现类注解
 * - name: 扩展点的名字
 * - ExtensionFactory: 获取具体实现的工厂
 * - 工厂，需要搭配注解@EnableAutoConfiguration使用
 *
 * @Author xudongchang
 * @Date 2023/9/27
 */
package com.timeline.vpn.common.extension;