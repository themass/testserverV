package com.timeline.vpn.util;

import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;

/***
 *
 * @author gqli
 *
 */
public class DateTimeUtils {

    public static final String TIMEFORMAT = "HHmmss";
    public static final String DATEFORMAT = "yyyyMMdd";
    public static final String MM_DD_E = "MM.dd(E)";
    public static final String DATETIMEFORMAT = DATEFORMAT + TIMEFORMAT;
    public static final String YYYY_MM_DDHH_MM = "yyyy-MM-dd HH:mm";
    public static final String YYYY_MM_DD = "yyyy-MM-dd";
    public static final String YYYY_MM_DDZZZ = "yyyy-MM-dd 00:00:00";
    public static final String YMDHHMM = "yyyyMMddHHmm";
    public static final String DATE_FORMAT = "yyyy-MM-dd HH:mm:ss";
    public static final String DATE_TZ_FORMAT = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    public static final String DATE_CN_FORMAT = "yyyy年MM月dd日HH时mm分ss秒";
    public static final String DATE_MM_DD = "MM月dd日";

    public static String getCurrentTimeString(String format, long mills) {
        SimpleDateFormat simpleFormat = new SimpleDateFormat(format);
        return simpleFormat.format(new Date(mills));
    }

    public static String formatDate(Date date) {
        if (date == null) {
            return null;
        }
        return formatDate(DATE_FORMAT, date);
    }

    public static String formatDate(String format, Date date) {
        if (date == null) {
            return null;
        }
        SimpleDateFormat simpleFormat = new SimpleDateFormat(format);
        return simpleFormat.format(date);
    }

    public static Date formatToDate(String format, String date) throws ParseException {
        if (date == null)
            return new Date();
        SimpleDateFormat sdf = new SimpleDateFormat(format);
        return sdf.parse(date);
    }

    /**
     * 返回当前时间的字符串，格式为yyyyMMddHHmmss。
     */
    public static String getCurrentTime() {
        return getCurrentTimeString(DATETIMEFORMAT, System.currentTimeMillis());
    }

    /**
     * 返回当前日期的字符串，格式为yyyyMMdd。
     */
    public static String getCurrentDate() {
        return getCurrentTimeString(DATEFORMAT, System.currentTimeMillis());
    }

    public static Date getTomorrow() {
        Calendar c = Calendar.getInstance();
        c.add(Calendar.DAY_OF_MONTH, 1);
        return c.getTime();
    }

    public static Date getYesterday() {
        Calendar c = Calendar.getInstance();
        c.add(Calendar.DAY_OF_MONTH, -1);
        return c.getTime();
    }

    /**
     * 获取日期,剔除毫秒
     */
    public static Date getDateWithoutHms(Date date) {
        Calendar c = Calendar.getInstance();
        c.setTime(date);
        c.set(Calendar.MILLISECOND, 0);
        c.set(Calendar.HOUR, 0);
        c.set(Calendar.MINUTE, 0);
        c.set(Calendar.SECOND, 0);
        return c.getTime();
    }

    /**
     * 返回给定时间的字符串yyyyMMddHHmmss与当前时间相差的分钟数。
     *
     */
    public static long getDifference(String mills) {
        if (mills.length() != 14) {
            return 0;
        } else {
            Calendar c = Calendar.getInstance(); // 当时的日期和时间
            Calendar c2 = Calendar.getInstance(); // 当时的日期和时间
            c2.set(Integer.parseInt(mills.substring(0, 4)),
                    Integer.parseInt(mills.substring(4, 6)) - 1,
                    Integer.parseInt(mills.substring(6, 8)),
                    Integer.parseInt(mills.substring(8, 10)),
                    Integer.parseInt(mills.substring(10, 12)),
                    Integer.parseInt(mills.substring(12, 14)));
            long ld = c.getTimeInMillis();// 返回ld 的时间值，以毫秒为单位
            long ld2 = c2.getTimeInMillis();// 返回ld2 的时间值，以毫秒为单位
            return (ld - ld2) / (60 * 1000);
        }
    }

    public static Date addMonth(Date date, int addMonth) {
        Calendar c = Calendar.getInstance();
        c.setTime(date);
        c.add(Calendar.MONTH, addMonth);
        return c.getTime();
    }

    public static Date addYear(Date date, int addYear) {
        Calendar c = Calendar.getInstance();
        c.setTime(date);
        c.add(Calendar.YEAR, addYear);
        return c.getTime();
    }

    public static Date addDay(Date date, int addDay) {
        Calendar c = Calendar.getInstance();
        c.setTime(date);
        c.add(Calendar.DAY_OF_MONTH, addDay);
        return c.getTime();
    }

    public static Date addHour(Date date, int addHour) {
        Calendar c = Calendar.getInstance();
        c.setTime(date);
        c.add(Calendar.HOUR, addHour);
        return c.getTime();
    }

    public static Date addMinute(Date date, int addMinute) {
        Calendar c = Calendar.getInstance();
        c.setTime(date);
        c.add(Calendar.MINUTE, addMinute);
        return c.getTime();
    }

    public static Date addSecond(Date date, int addSecond) {
        Calendar c = Calendar.getInstance();
        c.setTime(date);
        c.add(Calendar.SECOND, addSecond);
        return c.getTime();
    }

    public static Date getDateResetDHms(Date date, int addDay, int addHour, int addMinute,
            int addSecond) {
        Calendar c = Calendar.getInstance();
        c.setTime(date);
        c.set(Calendar.HOUR_OF_DAY, 0);
        c.set(Calendar.MINUTE, 0);
        c.set(Calendar.SECOND, 0);
        c.set(Calendar.MILLISECOND, 0);
        c.add(Calendar.DAY_OF_MONTH, addDay);
        c.add(Calendar.HOUR_OF_DAY, addHour);
        c.add(Calendar.MINUTE, addMinute);
        c.add(Calendar.SECOND, addSecond);
        return c.getTime();
    }

    public static long currentTimeSecond() {
        return System.currentTimeMillis() / 1000;
    }

    public static Date getGMTDate() {
        return addHour(new Date(), -8);
    }

    public static Integer getTimeByType(Date date, Integer type) {
        Calendar c = Calendar.getInstance();
        c.setTime(date);
        return c.get(type);
    }

    public static String getCnDate(Date date) {
        String time = formatDate(DATE_CN_FORMAT, date);
        return time.substring(0, 11);
    }
}
