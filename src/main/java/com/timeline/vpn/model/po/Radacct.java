package com.timeline.vpn.model.po;
/**
 * @author gqli
 * @date 2017年2月7日 上午1:26:55
 * @version V1.0
 */
public class Radacct {
    private int acctSessionTime;
    private long acctInputOctets;
    private long acctOutputOctets;
    private String connectInfoStart;
    public int getAcctSessionTime() {
        return acctSessionTime;
    }
    public void setAcctSessionTime(int acctSessionTime) {
        this.acctSessionTime = acctSessionTime;
    }
    public long getAcctInputOctets() {
        return acctInputOctets;
    }
    public void setAcctInputOctets(long acctInputOctets) {
        this.acctInputOctets = acctInputOctets;
    }
    public long getAcctOutputOctets() {
        return acctOutputOctets;
    }
    public void setAcctOutputOctets(long acctOutputOctets) {
        this.acctOutputOctets = acctOutputOctets;
    }
    public String getConnectInfoStart() {
        return connectInfoStart;
    }
    public void setConnectInfoStart(String connectInfoStart) {
        this.connectInfoStart = connectInfoStart;
    }
    
    
}

