package com.timeline.vpn.web.controller.api;

import cn.hutool.log.Log;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.Choice;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.service.impl.handle.chat.ChatDoubaoHandler;
import com.timeline.vpn.service.impl.handle.chat.ChatMyGpt4Handler;
import com.timeline.vpn.service.impl.handle.chat.KimiHandler;
import com.timeline.vpn.util.JsonUtil;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

/**
 * @author gqli
 * @date 2015年7月24日 下午3:16:25
 * @version V1.0
 */
@RestController
@RequestMapping("/api/test")
@Slf4j
public class TestController extends BaseController {
    @Autowired
    private KimiHandler chatMyGpt4Handler;
    @Autowired
    private ChatDoubaoHandler chatDoubaoHandler;
    @RequestMapping(value = "/test.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult recommendList(@UserInfo BaseQuery baseQuery) {
        Map<String, String> map = new HashMap<>();
        map.put("key", "test");
        return new JsonResult(map);
    }
    @RequestMapping(value = "/testmychat.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult testmychat(@UserInfo BaseQuery baseQuery, @RequestParam(name = "content") String content) throws Exception {
        Choice choice = chatMyGpt4Handler.chatWithGpt(baseQuery, content);
        log.info("kimi="+ JsonUtil.writeValueAsString(choice));
        choice = chatDoubaoHandler.chatWithGpt(baseQuery, content);
        log.info("doubao="+ JsonUtil.writeValueAsString(choice));
        return new JsonResult(choice);
    }
}

