package com.timeline.vpn.util;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

import java.net.URI;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.Base64;

/**
 * 解析用户节点分享链接，只提取列表展示与校验需要的字段（协议、名称、地址、端口）。
 * 连接用的完整 outbound 仍由客户端生成；服务端不信任客户端提交的这些字段，以这里解析的为准。
 * 只支持 vmess:// 与 trojan://，与客户端当前支持范围一致。
 */
public final class ShareLinkInfo {

    private static final ObjectMapper MAPPER = new ObjectMapper();

    public final String protocol;
    public final String name;
    public final String server;
    public final int port;

    private ShareLinkInfo(String protocol, String name, String server, int port) {
        this.protocol = protocol;
        this.name = name;
        this.server = server;
        this.port = port;
    }

    /** @throws IllegalArgumentException 格式不对或协议不支持 */
    public static ShareLinkInfo parse(String input) {
        String s = input == null ? "" : input.trim();
        try {
            if (s.startsWith("vmess://")) {
                return parseVmess(s);
            }
            if (s.startsWith("trojan://")) {
                return parseTrojan(s);
            }
        } catch (IllegalArgumentException e) {
            throw e;
        } catch (Exception e) {
            throw new IllegalArgumentException("链接格式不正确");
        }
        throw new IllegalArgumentException("暂不支持该协议");
    }

    private static ShareLinkInfo parseVmess(String uri) throws Exception {
        String json = new String(Base64.getDecoder().decode(uri.substring("vmess://".length()).trim()),
                StandardCharsets.UTF_8);
        JsonNode obj = MAPPER.readTree(json);
        String host = text(obj, "add");
        if (host.isEmpty()) {
            throw new IllegalArgumentException("链接里没有服务器地址");
        }
        int port = obj.has("port") ? obj.get("port").asInt(443) : 443;
        String name = text(obj, "ps");
        return new ShareLinkInfo("vmess", name.isEmpty() ? "vmess node" : name, host, port);
    }

    private static ShareLinkInfo parseTrojan(String uri) throws Exception {
        URI u = new URI(uri);
        if (u.getHost() == null || u.getHost().isEmpty()) {
            throw new IllegalArgumentException("链接里没有服务器地址");
        }
        int port = u.getPort() > 0 ? u.getPort() : 443;
        String frag = u.getRawFragment();
        String name = frag == null || frag.isEmpty() ? "trojan node"
                : URLDecoder.decode(frag, StandardCharsets.UTF_8.name());
        return new ShareLinkInfo("trojan", name, u.getHost(), port);
    }

    private static String text(JsonNode obj, String key) {
        JsonNode v = obj.get(key);
        return v == null || v.isNull() ? "" : v.asText("").trim();
    }
}
