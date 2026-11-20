package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.model.form.PageBaseForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.service.DataSubtitleService;
import com.timeline.vpn.web.common.resolver.UserInfo;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 视频字幕。挂在视频域下（/api/video/subtitle），命名对齐仓库原有接口：
 * items.json 走分页列表（PageBaseForm），item.json 单条取正文。
 *
 * <p>不 extends BaseController：只依赖一个 Service，显式构造器注入，
 * 测试可以 standaloneSetup(new SubtitleController(fake)) 直接起。
 *
 * @author gqli
 * @date 2026年11月21日
 * @version V1.0
 */
@RestController
@RequestMapping("/api/video/subtitle")
public class SubtitleController {
    private final DataSubtitleService dataSubtitleService;

    public SubtitleController(DataSubtitleService dataSubtitleService) {
        this.dataSubtitleService = dataSubtitleService;
    }

    @RequestMapping(value = "/items.json", method = {RequestMethod.POST, RequestMethod.GET})
    public JsonResult items(@UserInfo BaseQuery baseQuery,
            @ModelAttribute @Valid PageBaseForm form, @RequestParam(name = "id") long id) {
        return new JsonResult(dataSubtitleService.getSubtitlePage(baseQuery, form.toParam(), id));
    }

    @RequestMapping(value = "/item.json", method = {RequestMethod.POST, RequestMethod.GET})
    public JsonResult item(@UserInfo BaseQuery baseQuery, @RequestParam(name = "id") long id) {
        return new JsonResult(dataSubtitleService.getSubtitleContent(baseQuery, id));
    }

}
