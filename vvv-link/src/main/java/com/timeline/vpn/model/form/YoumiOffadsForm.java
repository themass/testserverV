package com.timeline.vpn.model.form;

import com.timeline.vpn.Constant;
import com.timeline.vpn.util.Md5;

/**
 * @author gqli
 * @date 2017年9月19日 上午10:59:39
 * @version V1.0
 */
public class YoumiOffadsForm {
    private String order;
    private String app;
    private String ad;
    private String user;
    private int chn;
    private float points;
    private String sig;
    private int adid;
    private String pkg;
    private String device;
    private int time;
    private float price;
    //1=>主任务；2=>附加任务(附加任务可能会有多个)；3=>分享主任务；4=>深度分享任务
    private int trade_type;
    private String _fb;
    public String getOrder() {
        return order;
    }
    public void setOrder(String order) {
        this.order = order;
    }
    public String getApp() {
        return app;
    }
    public void setApp(String app) {
        this.app = app;
    }
    public String getAd() {
        return ad;
    }
    public void setAd(String ad) {
        this.ad = ad;
    }
    public String getUser() {
        return user;
    }
    public void setUser(String user) {
        this.user = user;
    }
    public int getChn() {
        return chn;
    }
    public void setChn(int chn) {
        this.chn = chn;
    }
    public float getPoints() {
        return points;
    }
    public void setPoints(float points) {
        this.points = points;
    }
    public String getSig() {
        return sig;
    }
    public void setSig(String sig) {
        this.sig = sig;
    }
    public int getAdid() {
        return adid;
    }
    public void setAdid(int adid) {
        this.adid = adid;
    }
    public String getPkg() {
        return pkg;
    }
    public void setPkg(String pkg) {
        this.pkg = pkg;
    }
    public String getDevice() {
        return device;
    }
    public void setDevice(String device) {
        this.device = device;
    }
    public int getTime() {
        return time;
    }
    public void setTime(int time) {
        this.time = time;
    }
    public float getPrice() {
        return price;
    }
    public void setPrice(float price) {
        this.price = price;
    }
    public int getTrade_type() {
        return trade_type;
    }
    public void setTrade_type(int trade_type) {
        this.trade_type = trade_type;
    }
    public String get_fb() {
        return _fb;
    }
    public void set_fb(String _fb) {
        this._fb = _fb;
    }
    
    @Override
    public String toString() {
        return "YoumiOffadsForm [order=" + order + ", app=" + app + ", ad=" + ad + ", user=" + user
                + ", chn=" + chn + ", points=" + points + ", sig=" + sig + ", adid=" + adid
                + ", pkg=" + pkg + ", device=" + device + ", time=" + time + ", price=" + price
                + ", trade_type=" + trade_type + ", _fb=" + _fb + "]";
    }
    public boolean isRightReq(){
        String sigstr = Md5.encode(Constant.YOUMI_OFFADS + "||" + order + "||" + app + "||" + user + "||" + chn + "||" + ad + "||" + points).substring(12, 20);
        return sigstr.equals(sig);
    }
}

