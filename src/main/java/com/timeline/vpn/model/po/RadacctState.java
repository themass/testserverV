package com.timeline.vpn.model.po;
/**
 * @author gqli
 * @date 2017年2月7日 上午1:30:42
 * @version V1.0
 */
public class RadacctState {
    private Long acctSessionTime=0l;
    private Float accData=0f;
    public Long getAcctSessionTime() {
        return acctSessionTime==null?0:acctSessionTime;
    }
    public void setAcctSessionTime(Long acctSessionTime) {
        this.acctSessionTime = acctSessionTime;
    }
    public Float getAccData() {
        return accData==null?0:accData;
    }
    public void setAccData(Float accData) {
        this.accData = accData;
    }
    
    
}

