package vpn.model.vo;

/**
 * @author gqli
 * @date 2015年11月9日 下午1:36:19
 * @version V1.0
 */
public class VersionInfoVo {
    private String version;
    private String content;
    private String url;
    private int minBuild;
    private int maxBuild;
    private Boolean adsShow;
    private Boolean logUp;
    private StateUseVo stateUse;
    private String dnspodIp;
    private Boolean needDnspod=false;
    private String vpnUrl;
    private String vitamioExt;
    private VipDescVo vipDesc;
    private String qq;
    private Boolean showGdt;
    private boolean update = true;
    private  float traf=10;
    private Boolean chinaUser = false;
    private String userIp;
    private Boolean checkChina = true;
    public String asrDefaultCluster;
    public String appId;
    public String token;
    public String getVersion() {
        return version;
    }

    public void setVersion(String version) {
        this.version = version;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public int getMinBuild() {
        return minBuild;
    }

    public void setMinBuild(String minBuild) {
        this.minBuild = Integer.parseInt(minBuild);
    }

    public int getMaxBuild() {
        return maxBuild;
    }

    public void setMaxBuild(String maxBuild) {
        this.maxBuild = Integer.parseInt(maxBuild);
    }

    public Boolean getAdsShow() {
        return adsShow;
    }

    public void setAdsShow(Boolean adsShow) {
        this.adsShow = adsShow;
    }

    public Boolean getLogUp() {
        return logUp;
    }

    public void setLogUp(Boolean logUp) {
        this.logUp = logUp;
    }
    public StateUseVo getStateUse() {
        return stateUse;
    }

    public void setStateUse(StateUseVo stateUse) {
        this.stateUse = stateUse;
    }

    public String getDnspodIp() {
        return dnspodIp;
    }

    public void setDnspodIp(String dnspodIp) {
        this.dnspodIp = dnspodIp;
    }

    public Boolean getNeedDnspod() {
        return needDnspod;
    }

    public void setNeedDnspod(Boolean needDnspod) {
        this.needDnspod = needDnspod;
    }

    public String getVpnUrl() {
        return vpnUrl;
    }

    public void setVpnUrl(String vpnUrl) {
        this.vpnUrl = vpnUrl;
    }

    public String getVitamioExt() {
        return vitamioExt;
    }

    public void setVitamioExt(String vitamioExt) {
        this.vitamioExt = vitamioExt;
    }

    public VipDescVo getVipDesc() {
        return vipDesc;
    }

    public void setVipDesc(VipDescVo vipDesc) {
        this.vipDesc = vipDesc;
    }

    public String getQq() {
      return qq;
    }

    public void setQq(String qq) {
      this.qq = qq;
    }

    public Boolean getShowGdt() {
        return showGdt;
    }

    public void setShowGdt(Boolean showGdt) {
        this.showGdt = showGdt;
    }

    public boolean isUpdate() {
        return update;
    }

    public void setUpdate(boolean update) {
        this.update = update;
    }
    

    public float getTraf() {
        return traf;
    }

    public void setTraf(float traf) {
        this.traf = traf;
    }

    public Boolean getChinaUser() {
        return chinaUser;
    }

    public void setChinaUser(Boolean chinaUser) {
        this.chinaUser = chinaUser;
    }

    public String getUserIp() {
        return userIp;
    }

    public void setUserIp(String userIp) {
        this.userIp = userIp;
    }

    public void setMinBuild(int minBuild) {
        this.minBuild = minBuild;
    }

    public void setMaxBuild(int maxBuild) {
        this.maxBuild = maxBuild;
    }

    public Boolean getCheckChina() {
        return checkChina;
    }

    public void setCheckChina(Boolean checkChina) {
        this.checkChina = checkChina;
    }

    public String getAsrDefaultCluster() {
        return asrDefaultCluster;
    }

    public void setAsrDefaultCluster(String asrDefaultCluster) {
        this.asrDefaultCluster = asrDefaultCluster;
    }

    public String getAppId() {
        return appId;
    }

    public void setAppId(String appId) {
        this.appId = appId;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    @Override
    public String toString() {
        return "VersionInfoVo{" +
                "version='" + version + '\'' +
                ", content='" + content + '\'' +
                ", url='" + url + '\'' +
                ", minBuild=" + minBuild +
                ", maxBuild=" + maxBuild +
                ", adsShow=" + adsShow +
                ", logUp=" + logUp +
                ", stateUse=" + stateUse +
                ", dnspodIp='" + dnspodIp + '\'' +
                ", needDnspod=" + needDnspod +
                ", vpnUrl='" + vpnUrl + '\'' +
                ", vitamioExt='" + vitamioExt + '\'' +
                ", vipDesc=" + vipDesc +
                ", qq='" + qq + '\'' +
                ", showGdt=" + showGdt +
                ", update=" + update +
                ", traf=" + traf +
                ", chinaUser=" + chinaUser +
                ", userIp='" + userIp + '\'' +
                '}';
    }
}
