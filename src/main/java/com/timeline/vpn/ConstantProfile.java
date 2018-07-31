package com.timeline.vpn;


import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
@Component
public class ConstantProfile {
    public static String reportPath;

    @Value("${log.tmp.path}")
    public void setReportPath(String reportPath) {
        ConstantProfile.reportPath = reportPath;
    }
    
}
