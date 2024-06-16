package vpn.model.po;
/**
 * @author gqli
 * @date 2016年12月16日 下午3:45:55
 * @version V1.0
 */
public class DnsResverPo {
    private Integer id;
    private String  ip;
    private Integer ttl;
    private String domain;
    public String getIp() {
        return ip;
    }
    public void setIp(String ip) {
        this.ip = ip;
    }
    public Integer getTtl() {
        return ttl;
    }
    public void setTtl(Integer ttl) {
        this.ttl = ttl;
    }
    public String getDomain() {
        return domain;
    }
    public void setDomain(String domain) {
        this.domain = domain;
    }
    public Integer getId() {
        return id;
    }
    public void setId(Integer id) {
        this.id = id;
    }
    
    
}

