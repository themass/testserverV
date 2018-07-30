package com.timeline.vpn.model.form;

/**
 * @author gqli
 * @date 2017年8月17日 下午8:01:14
 * @version V1.0
 */
public class WeiXinForm{
    private String ToUserName;
    private String FromUserName;
    private String CreateTime;
    private String MsgType;
    private String Content;
    private Long MsgId;
    private String signature;
    private String timestamp;
    private String nonce;
    private String echostr;
    
    public String getToUserName() {
      return ToUserName;
    }
    public void setToUserName(String toUserName) {
      ToUserName = toUserName;
    }
    public String getFromUserName() {
      return FromUserName;
    }
    public void setFromUserName(String fromUserName) {
      FromUserName = fromUserName;
    }
    public String getCreateTime() {
      return CreateTime;
    }
    public void setCreateTime(String createTime) {
      CreateTime = createTime;
    }
    public String getMsgType() {
      return MsgType;
    }
    public void setMsgType(String msgType) {
      MsgType = msgType;
    }
    public String getContent() {
      return Content;
    }
    public void setContent(String content) {
      Content = content;
    }
    public Long getMsgId() {
      return MsgId;
    }
    public void setMsgId(Long msgId) {
      MsgId = msgId;
    }
    public String getSignature() {
      return signature;
    }
    public void setSignature(String signature) {
      this.signature = signature;
    }
    public String getTimestamp() {
      return timestamp;
    }
    public void setTimestamp(String timestamp) {
      this.timestamp = timestamp;
    }
    public String getNonce() {
      return nonce;
    }
    public void setNonce(String nonce) {
      this.nonce = nonce;
    }
    public String getEchostr() {
      return echostr;
    }
    public void setEchostr(String echostr) {
      this.echostr = echostr;
    }
    @Override
    public String toString() {
      return "WeiXinForm [ToUserName=" + ToUserName + ", FromUserName=" + FromUserName
          + ", CreateTime=" + CreateTime + ", MsgType=" + MsgType + ", Content=" + Content
          + ", MsgId=" + MsgId + ", signature=" + signature + ", timestamp=" + timestamp
          + ", nonce=" + nonce + ", echostr=" + echostr + "]";
    }
    
    
    
}

