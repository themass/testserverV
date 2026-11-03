package com.timeline.vpn.util;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.InputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.Signature;
import java.security.spec.X509EncodedKeySpec;
import java.util.Base64;
import java.util.HashMap;
import java.util.Map;

/**
 * 校验 AdMob 服务端回调（SSV）的签名。
 * <p>
 * 签名内容是回调 URL 中 {@code &signature=} 之前的原始查询串；签名为 ECDSA-SHA256，
 * 公钥由 Google 发布在 {@value #KEYS_URL}，按 key_id 选择。
 */
public final class AdmobSsvVerifier {

    private static final Logger LOGGER = LoggerFactory.getLogger(AdmobSsvVerifier.class);
    private static final String KEYS_URL = "https://www.gstatic.com/admob/reward/verifier-keys.json";
    private static final long KEYS_TTL_MS = 12L * 60 * 60 * 1000;
    private static final ObjectMapper MAPPER = new ObjectMapper();

    /**
     * 兜底公钥：Google 公开的验签公钥（keyId 3335741209，取自 KEYS_URL）。
     * 服务器访问不到 gstatic 时用它验签；Google 轮换公钥后这里要同步更新，
     * 远端拉取成功时会优先使用远端最新的公钥。
     */
    private static final String FALLBACK_KEY_ID = "3335741209";
    private static final String FALLBACK_KEY_BASE64 =
            "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE+nzvoGqvDeB9+SzE6igTl7TyK4JBbglwir9oTcQta8NuG26ZpZFxt+F2NDk7asTE6/2Yc8i1ATcGIqtuS5hv0Q==";

    private static volatile Map<Integer, PublicKey> keys = new HashMap<>();
    private static volatile long keysLoadedAt = 0;

    private AdmobSsvVerifier() {
    }

    /** @return 签名有效返回 true */
    public static boolean verify(String rawQuery) {
        if (rawQuery == null) {
            return false;
        }
        int sigAt = rawQuery.indexOf("&signature=");
        if (sigAt < 0) {
            LOGGER.warn("SSV 验签失败：查询串里没有 signature 参数: {}", rawQuery);
            return false;
        }
        String content = rawQuery.substring(0, sigAt);
        Map<String, String> params = parseParams(rawQuery);
        String sig = params.get("signature");
        String keyId = params.get("key_id");
        if (sig == null || keyId == null) {
            LOGGER.warn("SSV 验签失败：缺少 signature 或 key_id: {}", rawQuery);
            return false;
        }
        try {
            PublicKey key = publicKey(Integer.parseInt(keyId));
            if (key == null) {
                LOGGER.warn("SSV 验签失败：key_id={} 不在 Google 公钥列表中", keyId);
                return false;
            }
            Signature verifier = Signature.getInstance("SHA256withECDSA");
            verifier.initVerify(key);
            verifier.update(content.getBytes(StandardCharsets.UTF_8));
            boolean ok = verifier.verify(decodeBase64(sig));
            if (!ok) {
                LOGGER.warn("SSV 验签失败：签名不匹配 key_id={} query={}", keyId, rawQuery);
            }
            return ok;
        } catch (Exception e) {
            LOGGER.error("SSV 验签异常（常见原因：服务器访问不到 gstatic 公钥）: {}", e.toString());
            return false;
        }
    }

    /** 解析查询串（值做 URL 解码）。 */
    public static Map<String, String> parseParams(String rawQuery) {
        Map<String, String> result = new HashMap<>();
        for (String pair : rawQuery.split("&")) {
            int eq = pair.indexOf('=');
            if (eq <= 0) {
                continue;
            }
            result.put(pair.substring(0, eq), URLDecoder.decode(pair.substring(eq + 1), StandardCharsets.UTF_8));
        }
        return result;
    }

    private static byte[] decodeBase64(String value) {
        // 兼容标准与 URL 安全两种编码
        String normalized = value.replace('-', '+').replace('_', '/');
        return Base64.getDecoder().decode(normalized);
    }

    private static PublicKey publicKey(int keyId) throws Exception {
        long now = System.currentTimeMillis();
        if (!keys.containsKey(keyId) || now - keysLoadedAt > KEYS_TTL_MS) {
            try {
                loadKeys();
            } catch (Exception e) {
                // 远端拉取失败（常见于服务器访问不到 gstatic）：用内置兜底公钥
                LOGGER.warn("SSV 远端公钥拉取失败，使用内置兜底公钥: {}", e.toString());
                keys = fallbackKeys();
                keysLoadedAt = now;
            }
        }
        return keys.get(keyId);
    }

    private static Map<Integer, PublicKey> fallbackKeys() throws Exception {
        Map<Integer, PublicKey> fallback = new HashMap<>();
        KeyFactory factory = KeyFactory.getInstance("EC");
        byte[] der = Base64.getDecoder().decode(FALLBACK_KEY_BASE64);
        fallback.put(Integer.parseInt(FALLBACK_KEY_ID), factory.generatePublic(new X509EncodedKeySpec(der)));
        return fallback;
    }

    private static synchronized void loadKeys() throws Exception {
        HttpURLConnection conn = (HttpURLConnection) new URL(KEYS_URL).openConnection();
        conn.setConnectTimeout(5000);
        conn.setReadTimeout(5000);
        Map<Integer, PublicKey> loaded = new HashMap<>();
        try (InputStream in = conn.getInputStream()) {
            JsonNode root = MAPPER.readTree(in);
            KeyFactory factory = KeyFactory.getInstance("EC");
            for (JsonNode node : root.path("keys")) {
                byte[] der = Base64.getDecoder().decode(node.path("base64").asText());
                loaded.put(node.path("keyId").asInt(), factory.generatePublic(new X509EncodedKeySpec(der)));
            }
        } finally {
            conn.disconnect();
        }
        keys = loaded;
        keysLoadedAt = System.currentTimeMillis();
    }
}
