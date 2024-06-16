package vpn.model.po;

/**
 * @author gqli
 * @date 2015年11月9日 下午1:36:19
 * @version V1.0
 */
public class FileIpPo {
    private int id;
    private String type;
    private String ip;
    private String extra;
    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }
    public String getType() {
        return type;
    }
    public void setType(String type) {
        this.type = type;
    }
    public String getIp() {
        return ip;
    }
    public void setIp(String ip) {
        this.ip = ip;
    }
    public String getExtra() {
        return extra;
    }
    public void setExtra(String extra) {
        this.extra = extra;
    }


}
