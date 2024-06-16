package vpn.model.po;
/**
 * @author gqli
 * @date 2017年2月7日 上午1:26:55
 * @version V1.0
 */
public class Radacct {
    private long radacctid;
    private String from;
    private String to;
    private String nasipaddress;
    private String callingstationid;
    private int status;
    public String getFrom() {
        return from;
    }
    public void setFrom(String from) {
        this.from = from;
    }
    public String getTo() {
        return to;
    }
    public void setTo(String to) {
        this.to = to;
    }
    public String getNasipaddress() {
        return nasipaddress;
    }
    public void setNasipaddress(String nasipaddress) {
        this.nasipaddress = nasipaddress;
    }
    public String getCallingstationid() {
        return callingstationid;
    }
    public void setCallingstationid(String callingstationid) {
        this.callingstationid = callingstationid;
    }
    public int getStatus() {
        return status;
    }
    public void setStatus(int status) {
        this.status = status;
    }
    public long getRadacctid() {
        return radacctid;
    }
    public void setRadacctid(long radacctid) {
        this.radacctid = radacctid;
    }
    
    
}

