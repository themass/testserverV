package com.timeline.vpn.util;

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
 * @date 2017年4月5日 下午5:55:49
 * @version V1.0
 */
public class MailUtil {
    /**
     * 发送邮件到指定收件人。
     *
     * @return 发送成功返回 true；失败返回 false（调用方需据此告知用户，不能静默吞掉）
     */
    public static boolean sendMailTo(String to, String title, String msg) {
        final Properties props = new Properties();
        props.put("mail.smtp.auth", "true");
        props.put("mail.smtp.host", "smtp.163.com");
        props.put("mail.user", "freevpn_account@163.com");
        props.put("mail.password", "themass5296");
        Authenticator authenticator = new Authenticator() {
            @Override
            protected PasswordAuthentication getPasswordAuthentication() {
                return new PasswordAuthentication(props.getProperty("mail.user"),
                        props.getProperty("mail.password"));
            }
        };
        Session mailSession = Session.getInstance(props, authenticator);
        MimeMessage message = new MimeMessage(mailSession);
        try {
            message.setFrom(new InternetAddress(props.getProperty("mail.user")));
            message.setRecipient(RecipientType.TO, new InternetAddress(to));
            message.setSubject(title, "UTF-8");
            message.setContent(msg, "text/html;charset=UTF-8");
            Transport.send(message);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public static void sendMail(String title,String msg){
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
            InternetAddress to = new InternetAddress("freevpn_account@163.com");
            message.setRecipient(RecipientType.TO, to);
            // 设置邮件标题
            message.setSubject(title);
            message.setContent(msg,"text/html;charset=UTF-8");
            // 发送邮件
            Transport.send(message);
        } catch (Exception e) {
        }
    }
}

