package com.timeline.vpn.util;

public class UnicodeToChinese {
    public static String convertUnicode(String str) {
        StringBuilder result = new StringBuilder();
        int i = 0;
        while (i < str.length()) {
            if (str.charAt(i) == '\\' && i + 1 < str.length() && str.charAt(i + 1) == 'u') {
                // 提取 Unicode 编码
                String code = str.substring(i + 2, i + 6);
                try {
                    // 将 Unicode 编码转换为字符
                    char c = (char) Integer.parseInt(code, 16);
                    result.append(c);
                    i += 6;
                } catch (NumberFormatException e) {
                    // 如果编码格式错误，按原字符处理
                    result.append(str.charAt(i));
                    i++;
                }
            } else {
                result.append(str.charAt(i));
                i++;
            }
        }
        return result.toString();
    }

    public static void main(String[] args) {
        String unicodeStr = "\\u6587\\u6863\\u603b\\u7ed3\\u4e0e\\u5206\\u6790\n\n#### ";
        String chineseStr = convertUnicode(unicodeStr);
        System.out.println(chineseStr);
    }
}    