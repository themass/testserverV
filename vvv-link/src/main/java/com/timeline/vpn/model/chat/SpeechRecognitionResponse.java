package com.timeline.vpn.model.chat;

import lombok.Data;

import java.util.List;

// 顶层类，对应整个JSON对象
@Data
public class SpeechRecognitionResponse {
    private Results results;

    // getters 和 setters
    public Results getResults() {
        return results;
    }

    public void setResults(Results results) {
        this.results = results;
    }

    public static class Results {
        private List<Channel> channels;

        // getters 和 setters
        public List<Channel> getChannels() {
            return channels;
        }

        public void setChannels(List<Channel> channels) {
            this.channels = channels;
        }
    }

    // 表示单个通道的类，对应"channels"数组中的每个对象
    public static class Channel {
        private List<Alternative> alternatives;

        // getters 和 setters
        public List<Alternative> getAlternatives() {
            return alternatives;
        }

        public void setAlternatives(List<Alternative> alternatives) {
            this.alternatives = alternatives;
        }
    }

    // 表示每个通道中的备选方案的类，对应"alternatives"数组中的每个对象
    public static class Alternative {
        private String transcript;

        // getters 和 setters
        public String getTranscript() {
            return transcript;
        }

        public void setTranscript(String transcript) {
            this.transcript = transcript;
        }
    }
}

