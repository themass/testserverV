package vpn.service.job.reload;//package com.timeline.vpn.service.job.reload;
//
//import java.util.Date;
//
//import org.slf4j.Logger;
//import org.slf4j.LoggerFactory;
//import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.stereotype.Component;
//import org.springframework.transaction.annotation.Transactional;
//
//import com.timeline.vpn.dao.db.LockJobDao;
//import com.timeline.vpn.dao.db.UserDao;
//import com.timeline.vpn.model.po.LockJobPo;
//import com.timeline.vpn.service.job.ReloadJob;
//import com.timeline.vpn.util.DateTimeUtils;
//import com.timeline.vpn.util.IpLocalUtil;
//
///**
// * @author gqli
// * @date 2017年6月2日 下午9:35:47
// * @version V1.0
// */
//@Component
//public class ScoreCalculation extends ReloadJob{
//    private static final Logger LOGGER = LoggerFactory.getLogger(ScoreCalculation.class);
//    @Autowired
//    private UserDao userDao;
//    @Autowired
//    private LockJobDao lockJobDao;
//
//    @Override
//    @Transactional
//    public void reload() {
//        LockJobPo po = new LockJobPo();
//        po.setJobName("ScoreCalculation");
//        po.setJobTime(DateTimeUtils.formatDate(DateTimeUtils.YYYY_MM_DD,new Date()));
//        po.setIp(IpLocalUtil.getHostIp());
//       
//        if(lockJobDao.insert(po)>0) {
//            LOGGER.info("ScoreCalculation start");
////            userDao.minusScore();
////            userDao.minusScoreEx();
////            userDao.initUserVip();
////            userDao.initUserVip1();
////            userDao.initUserVip2();
//            LOGGER.info("ScoreCalculation end");
//        }
//    }
//}
//
