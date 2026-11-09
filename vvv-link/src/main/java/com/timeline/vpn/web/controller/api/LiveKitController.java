package com.timeline.vpn.web.controller.api;

import com.timeline.vpn.util.Secrets;

import com.timeline.vpn.model.param.BaseQuery;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.model.vo.Token;
import com.timeline.vpn.util.JsonUtil;
import com.timeline.vpn.web.common.resolver.UserInfo;
import com.timeline.vpn.web.controller.BaseController;
import io.livekit.server.AccessToken;
import io.livekit.server.RoomJoin;
import io.livekit.server.RoomName;
import io.livekit.server.RoomServiceClient;
import jakarta.validation.Valid;
import livekit.LivekitModels;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;
import retrofit2.Call;
import retrofit2.Response;


/**
 * @author gqli
 * @date 2015年7月24日 下午3:16:25
 * @version V1.0
 */
@RestController
@RequestMapping("/api/live/room")
@Slf4j
public class LiveKitController extends BaseController {
    @PostMapping(value = "/create.json")
    public JsonResult create(@UserInfo(required = true) BaseQuery baseQuery) throws Exception {

        RoomServiceClient client = RoomServiceClient.createClient(
                "http://example.com",
                Secrets.get("livekit.apiKey"),
                Secrets.get("livekit.apiSecretA"));

        Call<LivekitModels.Room> call = client.createRoom(baseQuery.getUser().getName()+"_room");
        Response<LivekitModels.Room> response = call.execute(); // Use call.enqueue for async
        LivekitModels.Room room = response.body();
        System.out.println(JsonUtil.writeValueAsString(room));
        return new JsonResult();
    }
    @PostMapping(value = "/token.json")
    public JsonResult token(@UserInfo(required = true) BaseQuery baseQuery) throws Exception {
        AccessToken token = new AccessToken(Secrets.get("livekit.apiKey"), Secrets.get("livekit.apiSecretB"));
        token.setName(baseQuery.getUser().getName());
        token.setIdentity(baseQuery.getUser().getName());
        token.setMetadata("metadata");
        token.addGrants(new RoomJoin(true), new RoomName(baseQuery.getUser().getName()+"_room"));
        System.out.println("New access token: " + token.toJwt());
        Token assToken = new Token();
        assToken.setToken(token.toJwt());
        assToken.setUrl(liveKitUrl());
        assToken.setRoomId(baseQuery.getUser().getName());
        assToken.setRoomName(baseQuery.getUser().getName()+"_room");
        return new JsonResult(assToken);
    }
    @PostMapping(value = "/token_new.json")
    public JsonResult tokenNew(@UserInfo(required = true) BaseQuery baseQuery) throws Exception {
        AccessToken token = new AccessToken(Secrets.get("livekit.apiKey"), Secrets.get("livekit.apiSecretB"));
        String tokenNanme = baseQuery.getUser().getName()+"_"+System.currentTimeMillis();
        token.setName("name");
        token.setIdentity("identity");
        token.setMetadata("metadata");
        token.addGrants(new RoomJoin(true), new RoomName(tokenNanme));
        System.out.println("New access token: " + token.toJwt());
        Token assToken = new Token();
        assToken.setToken(token.toJwt());
        assToken.setUrl(liveKitUrl());
        assToken.setRoomId(baseQuery.getUser().getName());
        assToken.setRoomName(tokenNanme);
        return new JsonResult(assToken);
    }

    /** LiveKit 服务地址，来自 secrets.properties 的 livekit.url。未配置直接报错，不回退到测试服务。 */
    private static String liveKitUrl() {
        String url = Secrets.get("livekit.url");
        if (url == null || url.isEmpty()) {
            throw new IllegalStateException("未配置 livekit.url（secrets.properties）");
        }
        return url;
    }

}
