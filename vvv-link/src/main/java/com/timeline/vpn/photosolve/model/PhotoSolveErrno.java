package com.timeline.vpn.photosolve.model;

import com.timeline.vpn.Constant;

/**
 * 拍照解题专用 errno（与聊天、登录等既有码分开编号，避免撞车）。
 *
 * 客户端按这些码分支处理（见 Android 端 PhotoSolveError）。**对外是接口契约**：
 * 码值不能改，只能新增。
 */
public final class PhotoSolveErrno {

    /** 图片不清晰：客户端提示重拍，可让用户选择「仍然提交」。 */
    public static final int BLURRY = 40001;

    /** 图片里没有题目：客户端回到取景/裁剪，提示重新对准。 */
    public static final int NOT_A_QUESTION = 40002;

    /** 图片过大或格式不支持：客户端压缩后重试一次。 */
    public static final int BAD_IMAGE = 40003;

    /** 额度用完。 */
    public static final int QUOTA_EXCEEDED = 42901;

    /** 全站当日预算用完（熔断）：不是这个用户的问题，客户端文案与 42901 区分开。 */
    public static final int BUDGET_EXHAUSTED = 42902;

    /** 模型服务失败 / 超时：可重试。 */
    public static final int MODEL_FAILED = 50001;

    /** 服务端未配置模型（缺 API Key / endpoint / model），属于部署问题。 */
    public static final int PROVIDER_NOT_CONFIGURED = 50002;

    /** 请求参数错误（缺图片、clientRequestId 为空等）。 */
    public static final int BAD_REQUEST = 40000;

    /** 默认的面向用户的错误文案。 */
    public static String messageOf(int errno) {
        switch (errno) {
            case BLURRY:
                return "图片不够清晰，建议重拍";
            case NOT_A_QUESTION:
                return "没有识别到题目，请重新对准题目";
            case BAD_IMAGE:
                return "图片过大或格式不支持";
            case QUOTA_EXCEEDED:
                return "今日识别额度已用完";
            case BUDGET_EXHAUSTED:
                return "今日识别服务已满，请明天再来";
            case MODEL_FAILED:
                return "识别服务暂时不可用，请重试";
            case PROVIDER_NOT_CONFIGURED:
                return "服务端未配置解题模型";
            case BAD_REQUEST:
                return "请求参数有误";
            default:
                return Constant.ResultMsg.RESULT_UNKNOWN;
        }
    }

    private PhotoSolveErrno() {
    }
}
