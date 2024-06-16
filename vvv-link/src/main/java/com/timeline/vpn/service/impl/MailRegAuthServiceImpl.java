package com.timeline.vpn.service.impl;

import com.timeline.vpn.exception.RegCodeException;
import com.timeline.vpn.service.CacheService;
import com.timeline.vpn.service.RegAuthService;
import com.timeline.vpn.util.CommonUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import javax.mail.Authenticator;
import javax.mail.Message.RecipientType;
import javax.mail.PasswordAuthentication;
import javax.mail.Session;
import javax.mail.Transport;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;
import java.util.Properties;

/**
 * @author gqli
 * @date 2016年12月27日 上午11:13:24
 * @version V1.0
 */
@Component
public class MailRegAuthServiceImpl implements RegAuthService{
    private static final Logger LOGGER = LoggerFactory.getLogger(MailRegAuthServiceImpl.class);
    @Autowired
    private CacheService cacheService;
    @Override
    public String reg(String channel) {
     // 配置发送邮件的环境属性
        final Properties props = new Properties();
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.host", "smtp.163.com");
        props.put("mail.user", "freevpn_account@163.com");
        props.put("mail.password", "themass5296");
        Authenticator authenticator = new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                // 用户名、密码
                String userName = props.getProperty("mail.user");
                String password = props.getProperty("mail.password");
                return new PasswordAuthentication(userName, password);
            }
        };
        Session mailSession = Session.getInstance(props, authenticator);
        MimeMessage message = new MimeMessage(mailSession);
        
        try {
            InternetAddress form = null;
            form = new InternetAddress(
                    props.getProperty("mail.user"));
            message.setFrom(form);
            InternetAddress to = new InternetAddress(channel);
            message.setRecipient(RecipientType.TO, to);
            // 设置邮件标题
            message.setSubject("New FreeVPN account");
            // 设置邮件的内容体
            String code = CommonUtil.generateCode();
            message.setContent("hello !["+code+"], Effective in 5 minutes","text/html;charset=UTF-8");
            // 发送邮件
            Transport.send(message);
            cacheService.put(channel, code,5);
            return code;
        } catch (Exception e) {
            LOGGER.error("",e);
            throw new RegCodeException();
        }
        
    }

    @Override
    public boolean check(String channel, String code) {
        return false;
    }
    public static void main(String[] args){
        MailRegAuthServiceImpl i = new MailRegAuthServiceImpl();
        i.reg("liguoqing19861028@163.com");
    }

}

