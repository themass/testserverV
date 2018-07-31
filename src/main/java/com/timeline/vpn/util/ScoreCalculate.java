package com.timeline.vpn.util;

import com.timeline.vpn.Constant;

/**
 * @author gqli
 * @date 2017年8月30日 下午10:09:05
 * @version V1.0
 */
public class ScoreCalculate {
    public static int level(Integer level,long score){
        if (level!=null && level==Constant.UserLevel.LEVEL_VIP3) {
          return Constant.UserLevel.LEVEL_VIP3;
        }
        if(score>=Constant.SCORE_TO_VIP&&score<Constant.SCORE_TO_VIP2){
            return Constant.UserLevel.LEVEL_VIP;
        }else if(score>=Constant.SCORE_TO_VIP2 &&score<Constant.SCORE_TO_VIP3){
                return Constant.UserLevel.LEVEL_VIP2;
        }else if(score>=Constant.SCORE_TO_VIP3){
            return Constant.UserLevel.LEVEL_VIP3;
        }
        return Constant.UserLevel.LEVEL_FREE;
    }
 
    
    public static String group(long level){
        if(level==Constant.UserLevel.LEVEL_FREE){
            return Constant.UserGroup.RAD_GROUP_REG;
        }
        return Constant.UserGroup.RAD_GROUP_VIP;
    }
}

