package com.timeline.vpn.web.controller.api;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.timeline.vpn.model.vo.JsonResult;
import com.timeline.vpn.model.vo.MyIpVo;
import com.timeline.vpn.util.UrlUtil;
import com.timeline.vpn.web.controller.BaseController;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;

/**
 * 网络体检：返回服务端看到的请求 IP，并在服务端查出城市。
 * App 的请求经过 VPN 时，这个 IP 就是节点出口。服务器在国内，直接查 IP 归属地，App 不依赖境外网站。
 */
@RestController
@RequestMapping("/api/net")
public class NetController extends BaseController {

    private static final Logger LOGGER = LoggerFactory.getLogger(NetController.class);
    private static final String GEO_URL = "https://whois.pconline.com.cn/ipJson.jsp?json=true&ip=";
    private static final int TIMEOUT_MS = 3000;
    private static final ObjectMapper MAPPER = new ObjectMapper();

    @RequestMapping(value = "/ip.json", method = {RequestMethod.GET, RequestMethod.POST})
    public JsonResult ip(HttpServletRequest request) {
        String ip = UrlUtil.getIpAddr(request);
        MyIpVo vo = new MyIpVo(ip);
        // 归属地查不到不影响返回 IP
        try {
            JsonNode node = MAPPER.readTree(fetchGeo(ip));
            vo.province = text(node, "pro");
            vo.city = text(node, "city");
        } catch (Exception e) {
            LOGGER.warn("IP 归属地查询失败 ip={}: {}", ip, e.toString());
        }
        return new JsonResult(vo);
    }

    private static String fetchGeo(String ip) throws Exception {
        HttpURLConnection conn = (HttpURLConnection) new URL(GEO_URL + URLEncoder.encode(ip, "UTF-8")).openConnection();
        conn.setConnectTimeout(TIMEOUT_MS);
        conn.setReadTimeout(TIMEOUT_MS);
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(conn.getInputStream(), "GBK"))) {
            StringBuilder sb = new StringBuilder();
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line);
            }
            return sb.toString();
        } finally {
            conn.disconnect();
        }
    }

    private static String text(JsonNode node, String key) {
        JsonNode value = node.get(key);
        if (value == null || value.isNull()) {
            return null;
        }
        String s = value.asText().trim();
        return s.isEmpty() ? null : s;
    }
}
