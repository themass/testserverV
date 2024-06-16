package vpn.model.po;
/**
 * @author gqli
 * @date 2017年12月28日 下午10:30:07
 * @version V1.0
 */
public class PingCheck {
    private int type;
    private String ip;
    public PingCheck(){}
    public PingCheck(String ip,int type){
        this.ip = ip;
        this.type = type;
    }
    public int getType() {
        return type;
    }
    public void setType(int type) {
        this.type = type;
    }
    public String getIp() {
        return ip;
    }
    public void setIp(String ip) {
        this.ip = ip;
    }
    
}

