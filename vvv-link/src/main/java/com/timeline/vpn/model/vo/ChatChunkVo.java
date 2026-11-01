package com.timeline.vpn.model.vo;

import java.util.List;

/** 上游 OpenAI 兼容流式响应里，每个 `data: {...}` 行反序列化出来的结构。 */
public class ChatChunkVo {
    private List<ChunkChoice> choices;

    public List<ChunkChoice> getChoices() {
        return choices;
    }

    public void setChoices(List<ChunkChoice> choices) {
        this.choices = choices;
    }

    public static class ChunkChoice {
        private ChunkDelta delta;
        private String finish_reason;

        public ChunkDelta getDelta() {
            return delta;
        }

        public void setDelta(ChunkDelta delta) {
            this.delta = delta;
        }

        public String getFinish_reason() {
            return finish_reason;
        }

        public void setFinish_reason(String finish_reason) {
            this.finish_reason = finish_reason;
        }
    }

    public static class ChunkDelta {
        private String role;
        private String content;

        public String getRole() {
            return role;
        }

        public void setRole(String role) {
            this.role = role;
        }

        public String getContent() {
            return content;
        }

        public void setContent(String content) {
            this.content = content;
        }
    }
}
