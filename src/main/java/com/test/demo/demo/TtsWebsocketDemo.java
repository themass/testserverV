package com.test.demo.demo;

import com.alibaba.fastjson.JSON;
import lombok.Getter;
import org.java_websocket.client.WebSocketClient;
import org.java_websocket.framing.CloseFrame;
import org.java_websocket.handshake.ServerHandshake;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.io.*;
import java.math.BigInteger;
import java.net.URI;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.UUID;

public class TtsWebsocketDemo {
    private static final Logger log = LoggerFactory.getLogger(TtsWebsocketDemo.class);
    public static final String API_URL = "wss://openspeech.bytedance.com/api/v1/tts/ws_binary";

    public static void main(String[] args) throws Exception {
        // set your appid and access_token
        String appid = "5133267845";
        String accessToken = "6_OzctVW03tghjl3up5BysHG_smYe3RK";
        String uid = "388808087185088";


        TtsRequest ttsRequest = TtsRequest.builder()
            .app(TtsRequest.App.builder()
                .appid(appid)
                .cluster("volcano_tts")
                .build())
            .user(TtsRequest.User.builder()
                .uid(uid)
                .build())
            .audio(TtsRequest.Audio.builder()
                .encoding("mp3")
                .voiceType("BV001_streaming")
                .build())
            .request(TtsRequest.Request.builder()
                .reqID(UUID.randomUUID().toString())
                .operation("query")
                .text("字节跳动语音合成")
                .build())
            .build();
        TtsWebsocketClient ttsWebsocketClient = new TtsWebsocketClient(accessToken);
        byte[] audio = ttsWebsocketClient.submit(ttsRequest);
        FileOutputStream fos = new FileOutputStream("test.mp3");
        fos.write(audio);
        fos.close();
        log.info("TTS done.");
    }

    public static class TtsWebsocketClient extends WebSocketClient {
        private final ByteArrayOutputStream buffer = new ByteArrayOutputStream();

        public TtsWebsocketClient(String accessToken) {
            super(URI.create(API_URL), Collections.singletonMap("Authorization", "Bearer; " + accessToken));
        }

        public byte[] submit(TtsRequest ttsRequest) throws InterruptedException {
            String json = JSON.toJSONString(ttsRequest);
            log.info("request: {}", json);
            byte[] jsonBytes = json.getBytes(StandardCharsets.UTF_8);
            byte[] header = {0x11, 0x10, 0x10, 0x00};
            ByteBuffer requestByte = ByteBuffer.allocate(8 + jsonBytes.length);
            requestByte.put(header).putInt(jsonBytes.length).put(jsonBytes);

            this.connectBlocking();
            synchronized (this) {
                this.send(requestByte.array());
                wait();
                return this.buffer.toByteArray();
            }
        }

        @Override
        public void onMessage(ByteBuffer bytes) {
            int protocolVersion = (bytes.get(0) & 0xff) >> 4;
            int headerSize = bytes.get(0) & 0x0f;
            int messageType = (bytes.get(1) & 0xff) >> 4;
            int messageTypeSpecificFlags = bytes.get(1) & 0x0f;
            int serializationMethod = (bytes.get(2) & 0xff) >> 4;
            int messageCompression = bytes.get(2) & 0x0f;
            int reserved = bytes.get(3) & 0xff;
            bytes.position(headerSize * 4);
            byte[] fourByte = new byte[4];
            if (messageType == 11) {
                // Audio-only server response
                log.info("received audio-only response.");
                if (messageTypeSpecificFlags == 0) {
                    // Ack without audio data
                } else {
                    bytes.get(fourByte, 0, 4);
                    int sequenceNumber = new BigInteger(fourByte).intValue();
                    bytes.get(fourByte, 0, 4);
                    int payloadSize = new BigInteger(fourByte).intValue();
                    byte[] payload = new byte[payloadSize];
                    bytes.get(payload, 0, payloadSize);
                    try {
                        this.buffer.write(payload);
                    } catch (IOException e) {
                        throw new RuntimeException(e);
                    }
                    if (sequenceNumber < 0) {
                        // received the last segment
                        this.close(CloseFrame.NORMAL, "received all audio data.");
                    }
                }
            } else if (messageType == 15) {
                // Error message from server
                bytes.get(fourByte, 0, 4);
                int code = new BigInteger(fourByte).intValue();
                bytes.get(fourByte, 0, 4);
                int messageSize = new BigInteger(fourByte).intValue();
                byte[] messageBytes = new byte[messageSize];
                bytes.get(messageBytes, 0, messageSize);
                String message = new String(messageBytes, StandardCharsets.UTF_8);
                throw new TtsException(code, message);
            } else {
                log.warn("Received unknown response message type: {}", messageType);
            }
        }

        @Override
        public void onOpen(ServerHandshake serverHandshake) {
            log.info("opened connection");
        }

        @Override
        public void onMessage(String message) {
            log.info("received message: " + message);
        }

        @Override
        public void onClose(int code, String reason, boolean remote) {
            log.info("Connection closed by {}, Code: {}, Reason: {}", (remote ? "remote" : "us"), code, reason);
            synchronized (this) {
                notify();
            }
        }

        @Override
        public void onError(Exception e) {
            close(CloseFrame.NORMAL, e.toString());
        }
    }

    @Getter
    public static class TtsException extends RuntimeException {
        private final int code;
        private final String message;

        public TtsException(int code, String message) {
            super("code=" + code + ", message=" + message);
            this.code = code;
            this.message = message;
        }
    }
}