package vpn.util;

import com.timeline.vpn.Constant;
import com.timeline.vpn.model.po.UserPo;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.Date;

/**
 * @author gqli
 * @date 2017年8月30日 下午10:09:05
 * @version V1.0
 */
public class ScoreCalculate {
    private static final Logger LOGGER = LoggerFactory.getLogger(ScoreCalculate.class);

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
    public static int calculate(UserPo po){
        LOGGER.info("calculate--"+po.getName()+"---"+po.getLevel()+"---"+po.getScore()+"---"+DateTimeUtils.formatDate(po.getPaidEndTime()));
        if(po.getLevel()==Constant.UserLevel.LEVEL_FREE) {
            if(po.getScore()>Constant.SCORE_TO_VIP2) {
                po.setLevel(Constant.UserLevel.LEVEL_VIP2);
                po.setScore(po.getScore()-Constant.SCORE_TO_VIP2);
                po.setPaidStartTime(DateTimeUtils.getDateWithoutHms(new Date()));
                po.setPaidEndTime(DateTimeUtils.addDay(po.getPaidStartTime(), 30));
                return 1;
            }else if(po.getScore()>Constant.SCORE_TO_VIP){
                po.setLevel(Constant.UserLevel.LEVEL_VIP);
                po.setScore(po.getScore()-Constant.SCORE_TO_VIP);
                po.setPaidStartTime(DateTimeUtils.getDateWithoutHms(new Date()));
                po.setPaidEndTime(DateTimeUtils.addDay(po.getPaidStartTime(), 30));
                return 1;
            }
        }else if(po.getLevel()==Constant.UserLevel.LEVEL_VIP) {
            if(po.getScore()>Constant.SCORE_TO_VIP2) {
                po.setLevel(Constant.UserLevel.LEVEL_VIP2);
                po.setScore(po.getScore()-Constant.SCORE_TO_VIP2);
                po.setPaidStartTime(DateTimeUtils.getDateWithoutHms(new Date()));
                po.setPaidEndTime(DateTimeUtils.addDay(po.getPaidStartTime(), 42));
                return 1;
            }
        }else if(po.getLevel()==Constant.UserLevel.LEVEL_VIP2) {
            if(po.getScore()>Constant.SCORE_TO_VIP2) {
                po.setLevel(Constant.UserLevel.LEVEL_VIP2);
                po.setScore(po.getScore()-Constant.SCORE_TO_VIP2);
                po.setPaidStartTime(DateTimeUtils.getDateWithoutHms(new Date()));
                Date enDate = po.getPaidEndTime()==null?po.getPaidStartTime():po.getPaidEndTime();
                po.setPaidEndTime(DateTimeUtils.addDay(enDate, 30));
                return 1;
            }
        }
        return 0;
    }
    
    public static String group(long level){
        if(level==Constant.UserLevel.LEVEL_FREE){
            return Constant.UserGroup.RAD_GROUP_REG;
        }
        return Constant.UserGroup.RAD_GROUP_VIP;
    }
    public static void main(String[]agrs) {
        UserPo po = new UserPo();
        po.setLevel(3);
        po.setScore(4501);
        po.setPaidEndTime(DateTimeUtils.addDay(new Date(), 30));
        ScoreCalculate.calculate(po);
        System.out.println(po);
    }
}

