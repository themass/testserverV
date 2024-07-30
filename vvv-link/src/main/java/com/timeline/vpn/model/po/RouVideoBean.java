package com.timeline.vpn.model.po;

public class RouVideoBean {
    private Video video;

    public Video getVideo() {
        return video;
    }

    public void setVideo(Video video) {
        this.video = video;
    }

    public static class Video {
        private String thumbVTTUrl;
        private String videoUrl;

        public String getThumbVTTUrl() {
            return thumbVTTUrl;
        }

        public void setThumbVTTUrl(String thumbVTTUrl) {
            this.thumbVTTUrl = thumbVTTUrl;
        }

        public String getVideoUrl() {
            return videoUrl;
        }

        public void setVideoUrl(String videoUrl) {
            this.videoUrl = videoUrl;
        }
    }
}
