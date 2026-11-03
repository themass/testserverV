package com.timeline.vpn.util;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

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

    private static final String KEYS_URL = "https://www.gstatic.com/admob/reward/verifier-keys.json";
    private static final long KEYS_TTL_MS = 12L * 60 * 60 * 1000;
    private static final ObjectMapper MAPPER = new ObjectMapper();

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
            return false;
        }
        String content = rawQuery.substring(0, sigAt);
        Map<String, String> params = parseParams(rawQuery);
        String sig = params.get("signature");
        String keyId = params.get("key_id");
        if (sig == null || keyId == null) {
            return false;
        }
        try {
            PublicKey key = publicKey(Integer.parseInt(keyId));
            if (key == null) {
                return false;
            }
            Signature verifier = Signature.getInstance("SHA256withECDSA");
            verifier.initVerify(key);
            verifier.update(content.getBytes(StandardCharsets.UTF_8));
            return verifier.verify(decodeBase64(sig));
        } catch (Exception e) {
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
            loadKeys();
        }
        return keys.get(keyId);
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
