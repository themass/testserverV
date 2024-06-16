package vpn.model.po;
/**
 * @author gqli
 * @date 2018年7月21日 下午10:28:07
 * @version V1.0
 */
public class LockJobPo {
    private String jobName;
    private String jobTime;
    private String ip;
    public String getJobName() {
        return jobName;
    }
    public void setJobName(String jobName) {
        this.jobName = jobName;
    }
    public String getJobTime() {
        return jobTime;
    }
    public void setJobTime(String jobTime) {
        this.jobTime = jobTime;
    }
    public String getIp() {
        return ip;
    }
    public void setIp(String ip) {
        this.ip = ip;
    }
    
}

