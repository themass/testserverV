package com.timeline.vpn.model.po;
/**
 * @author gqli
 * @date 2017年2月7日 上午1:30:42
 * @version V1.0
 */
public class RadacctState {
    private Integer acctSessionTime;
    private Double acctInputOctets;
    private Double acctOutputOctets;
    public int getAcctSessionTime() {
        return acctSessionTime==null?0:acctSessionTime;
    }
    public void setAcctSessionTime(Integer acctSessionTime) {
        this.acctSessionTime = acctSessionTime;
    }
    public double getAcctInputOctets() {
        return acctInputOctets==null?0:acctInputOctets;
    }
    public void setAcctInputOctets(Double acctInputOctets) {
        this.acctInputOctets = acctInputOctets;
    }
    public double getAcctOutputOctets() {
        return acctOutputOctets==null?0:acctOutputOctets;
    }
    public void setAcctOutputOctets(Double acctOutputOctets) {
        this.acctOutputOctets = acctOutputOctets;
    }
    
    
}

