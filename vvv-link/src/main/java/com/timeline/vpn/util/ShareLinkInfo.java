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
 * 支持 vmess:// trojan:// vless:// ss:// hy2:// hysteria2://，与客户端 UserNodeStore 的范围一致。
 * 只需要地址和端口，所以 userinfo（密码、UUID、加密方式）一律不解析、不存库。
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
            if (s.startsWith("vless://")) {
                return parseAuthorityUri("vless", s, 443);
            }
            if (s.startsWith("ss://")) {
                return parseShadowsocks(s);
            }
            if (s.startsWith("hy2://") || s.startsWith("hysteria2://")) {
                return parseAuthorityUri("hysteria2", s, 443);
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

    /**
     * 形如 scheme://userinfo@host:port?query#name 的链接。不用 java.net.URI：
     * 密码或 base64 里的 / + = 等字符会让 URI 直接抛异常。
     */
    private static ShareLinkInfo parseAuthorityUri(String protocol, String uri, int defaultPort) {
        String body = uri.substring(uri.indexOf("://") + 3);
        String name = fragmentName(body, protocol);
        body = stripFragmentAndQuery(body);
        int at = body.lastIndexOf('@');
        if (at < 0) {
            throw new IllegalArgumentException("链接里没有服务器地址");
        }
        return withHostPort(protocol, name, body.substring(at + 1), defaultPort);
    }

    /**
     * ss:// 有两种写法：SIP002 是 ss://base64(method:pass)@host:port#name，
     * 旧式是 ss://base64(method:pass@host:port)#name。两种都只取 host:port。
     */
    private static ShareLinkInfo parseShadowsocks(String uri) {
        String body = uri.substring("ss://".length());
        String name = fragmentName(body, "shadowsocks");
        body = stripFragmentAndQuery(body);
        if (!body.contains("@")) {
            try {
                body = new String(Base64.getDecoder().decode(body), StandardCharsets.UTF_8);
            } catch (IllegalArgumentException e) {
                throw new IllegalArgumentException("链接格式不正确");
            }
        }
        int at = body.lastIndexOf('@');
        if (at < 0) {
            throw new IllegalArgumentException("链接里没有服务器地址");
        }
        return withHostPort("shadowsocks", name, body.substring(at + 1), 8388);
    }

    private static ShareLinkInfo withHostPort(String protocol, String name, String authority,
                                              int defaultPort) {
        String host;
        String portPart = "";
        if (authority.startsWith("[")) {
            int end = authority.indexOf(']');
            if (end < 0) {
                throw new IllegalArgumentException("链接格式不正确");
            }
            host = authority.substring(1, end);
            if (end + 1 < authority.length()) {
                if (authority.charAt(end + 1) != ':') {
                    throw new IllegalArgumentException("链接格式不正确");
                }
                portPart = authority.substring(end + 2);
            }
        } else {
            int colon = authority.lastIndexOf(':');
            host = colon < 0 ? authority : authority.substring(0, colon);
            portPart = colon < 0 ? "" : authority.substring(colon + 1);
        }
        if (host.isEmpty()) {
            throw new IllegalArgumentException("链接里没有服务器地址");
        }
        int port = defaultPort;
        if (!portPart.isEmpty()) {
            try {
                port = Integer.parseInt(portPart);
            } catch (NumberFormatException e) {
                throw new IllegalArgumentException("链接里的端口不正确");
            }
        }
        if (port <= 0 || port > 65535) {
            throw new IllegalArgumentException("链接里的端口不正确");
        }
        return new ShareLinkInfo(protocol, name, host, port);
    }

    /** 取 # 之后的备注名（URL 解码），没有则用协议名。 */
    private static String fragmentName(String body, String protocol) {
        int hash = body.indexOf('#');
        if (hash < 0 || hash + 1 >= body.length()) {
            return protocol + " node";
        }
        try {
            String name = URLDecoder.decode(body.substring(hash + 1), StandardCharsets.UTF_8.name()).trim();
            return name.isEmpty() ? protocol + " node" : name;
        } catch (Exception e) {
            return protocol + " node";
        }
    }

    private static String stripFragmentAndQuery(String body) {
        int cut = body.length();
        int hash = body.indexOf('#');
        if (hash >= 0) {
            cut = Math.min(cut, hash);
        }
        int q = body.indexOf('?');
        if (q >= 0) {
            cut = Math.min(cut, q);
        }
        return body.substring(0, cut);
    }

    private static String text(JsonNode obj, String key) {
        JsonNode v = obj.get(key);
        return v == null || v.isNull() ? "" : v.asText("").trim();
    }
}
