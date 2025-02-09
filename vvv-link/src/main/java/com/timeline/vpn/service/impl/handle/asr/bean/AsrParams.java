package com.timeline.vpn.service.impl.handle.asr.bean;

public class AsrParams {
    private App app;
    private User user;
    private Request request;
    private Audio audio;

    public AsrParams(App app, User user, Request request, Audio audio) {
        this.app = app;
        this.user = user;
        this.request = request;
        this.audio = audio;
    }

    public App getApp() {
        return app;
    }

    public void setApp(App app) {
        this.app = app;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public Request getRequest() {
        return request;
    }

    public void setRequest(Request request) {
        this.request = request;
    }

    public Audio getAudio() {
        return audio;
    }

    public void setAudio(Audio audio) {
        this.audio = audio;
    }

    public static class App {
        private String appid;
        private String cluster;
        private String token;

        public App(String appid, String cluster, String token) {
            this.appid = appid;
            this.cluster = cluster;
            this.token = token;
        }

        public String getAppid() {
            return appid;
        }

        public void setAppid(String appid) {
            this.appid = appid;
        }

        public String getCluster() {
            return cluster;
        }

        public void setCluster(String cluster) {
            this.cluster = cluster;
        }

        public String getToken() {
            return token;
        }

        public void setToken(String token) {
            this.token = token;
        }
    }

    public static class User {
        private String uid;

        public User(String uid) {
            this.uid = uid;
        }

        public String getUid() {
            return uid;
        }

        public void setUid(String uid) {
            this.uid = uid;
        }
    }

    public static class Request {
        private String reqid;
        private String workflow;
        private int nbest;
        private boolean show_utterances;
        private String result_type;
        private int sequence;

        public Request(String reqid, String workflow, int nbest, boolean show_utterances, String result_type, int sequence) {
            this.reqid = reqid;
            this.workflow = workflow;
            this.nbest = nbest;
            this.show_utterances = show_utterances;
            this.result_type = result_type;
            this.sequence = sequence;
        }

        public String getReqid() {
            return reqid;
        }

        public void setReqid(String reqid) {
            this.reqid = reqid;
        }

        public String getWorkflow() {
            return workflow;
        }

        public void setWorkflow(String workflow) {
            this.workflow = workflow;
        }

        public int getNbest() {
            return nbest;
        }

        public void setNbest(int nbest) {
            this.nbest = nbest;
        }

        public boolean isShow_utterances() {
            return show_utterances;
        }

        public void setShow_utterances(boolean show_utterances) {
            this.show_utterances = show_utterances;
        }

        public String getResult_type() {
            return result_type;
        }

        public void setResult_type(String result_type) {
            this.result_type = result_type;
        }

        public int getSequence() {
            return sequence;
        }

        public void setSequence(int sequence) {
            this.sequence = sequence;
        }
    }

    public static class Audio {
        private String format;
        private String codec;
        private int rate;
        private int bits;
        private int channels;

        public Audio(String format, String codec, int rate, int bits, int channels) {
            this.format = format;
            this.codec = codec;
            this.rate = rate;
            this.bits = bits;
            this.channels = channels;
        }

        public String getFormat() {
            return format;
        }

        public void setFormat(String format) {
            this.format = format;
        }

        public String getCodec() {
            return codec;
        }

        public void setCodec(String codec) {
            this.codec = codec;
        }

        public int getRate() {
            return rate;
        }

        public void setRate(int rate) {
            this.rate = rate;
        }

        public int getBits() {
            return bits;
        }

        public void setBits(int bits) {
            this.bits = bits;
        }

        public int getChannels() {
            return channels;
        }

        public void setChannels(int channels) {
            this.channels = channels;
        }
    }
}
