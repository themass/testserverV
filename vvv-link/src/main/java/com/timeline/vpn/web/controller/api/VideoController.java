package vpn.web.controller.api;

import com.timeline.vpn.Constant;
import com.timeline.vpn.model.form.ChannelItemsForm;
import com.timeline.vpn.model.form.PageBaseForm;
import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;
import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

import javax.validation.Valid;

/**
 * @author gqli
 * @date 2015年7月24日 下午3:16:25
 * @version V1.0
 */
@Controller
@RequestMapping("/api/video")
public class VideoController extends BaseController {
    @RequestMapping(value = "/items.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult items(@UserInfo BaseQuery baseQuery,
            @ModelAttribute @Valid PageBaseForm form) { 
        return new JsonResult(dataVideoService.getVideoPage(baseQuery, form.toParam()));
    }
    @RequestMapping(value = "/channel.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult channel(@UserInfo BaseQuery baseQuery,@RequestParam(defaultValue=Constant.VideoShowType.NORMAL) String channel) {
        return new JsonResult(dataVideoService.getVideoChannel(baseQuery,channel));
    }
    @RequestMapping(value = "/channel/items.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult channelItems(@UserInfo BaseQuery baseQuery,@ModelAttribute @Valid ChannelItemsForm form) {
        return new JsonResult(dataVideoService.getVideoChannelItemsPage(baseQuery, form.toParam(),form.getChannel(),form.getKeyword(),form.getChannelOrg()));
    } 
    @RequestMapping(value = "/user.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult user(@UserInfo BaseQuery baseQuery,
            @ModelAttribute @Valid PageBaseForm form,@RequestParam(required=false) String channel) {
        if(StringUtils.isEmpty(channel)) {
            channel = "人气女优";
        }
        return new JsonResult(dataVideoService.getVideoUserPage(baseQuery, form.toParam(),channel));
    } 
    @RequestMapping(value = "/user/items.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult userItems(@UserInfo BaseQuery baseQuery,
            @ModelAttribute @Valid PageBaseForm form,@RequestParam String userId,@ModelAttribute @Valid ChannelItemsForm keyword) {
        return new JsonResult(dataVideoService.getVideoUserItemsPage(baseQuery, form.toParam(),userId,keyword.getKeyword()));
    }
    @RequestMapping(value = "/tv/channel.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult tvChannel(@UserInfo BaseQuery baseQuery,@ModelAttribute @Valid ChannelItemsForm form) {
        return new JsonResult(dataVideoService.getVideoTvChannelPage(baseQuery, form.toParam(), form.getChannelOrg(),form.getKeyword()));
    }
    @RequestMapping(value = "/tv/item.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult tvItem(@UserInfo BaseQuery baseQuery,
            @ModelAttribute @Valid PageBaseForm form,@RequestParam String channel) {
        return new JsonResult(dataVideoService.getVideoTvItemPage(baseQuery, form.toParam(), channel));
    }
    @RequestMapping(value = "/item/url.json", method = {RequestMethod.POST,RequestMethod.GET})
    public JsonResult url(@UserInfo BaseQuery baseQuery,
            @ModelAttribute @Valid PageBaseForm form,@RequestParam long id) {
        return new JsonResult(dataVideoService.getVideoUrl(baseQuery, form.toParam(), id));
    }
    
}

