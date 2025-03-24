package com.timeline.vpn.util;

import java.util.Arrays;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class LaTeXFormulaReplacer {
    private static String replaceMathDelimiters(String input) {
        // 替换 \[ ... \] 为 $$ ... $$
        String result = replaceDelimiter(input, "\\\\[", "\\\\]", "$$");
        // 替换 \( ... \) 为 $ ... $
        result = replaceDelimiter(result, "\\\\(", "\\\\)", "$");
        return result;
    }

    private static String replaceDelimiter(String input, String startDelimiter, String endDelimiter, String replacementDelimiter) {
        StringBuilder sb = new StringBuilder();
        int index = 0;
        while (index < input.length()) {
            int startIndex = input.indexOf(startDelimiter, index);
            if (startIndex == -1) {
                sb.append(input.substring(index));
                break;
            }
            sb.append(input, index, startIndex);
            int endIndex = input.indexOf(endDelimiter, startIndex + startDelimiter.length());
            if (endIndex == -1) {
                sb.append(input.substring(startIndex));
                break;
            }
            sb.append(replacementDelimiter);
            sb.append(input, startIndex + startDelimiter.length(), endIndex);
            sb.append(replacementDelimiter);
            index = endIndex + endDelimiter.length();
        }
        return sb.toString();
    }
    private static String replaceString(String input) {
        StringBuilder result = new StringBuilder();
        input = input.replace("`$`","!MY010MY!").replace("`$$`","!!MY010010MY!!");
        int i = 0;
        while (i < input.length()) {
            if (i + 1 < input.length() && input.charAt(i) == '$' && input.charAt(i + 1) == '$') {
                // 处理双$情况
                int endIndex = input.indexOf("$$", i + 2);
                if (endIndex != -1) {
                    result.append(input, i, endIndex + 2);
                    i = endIndex + 2;
                } else {
                    result.append(input.charAt(i));
                    i++;
                }
            } else if (input.charAt(i) == '$') {
                // 处理单$情况
                int endIndex = input.indexOf('$', i + 1);
                if (endIndex != -1) {
                    result.append('$');
                    result.append(input, i + 1, endIndex);
                    result.append('$');
                    i = endIndex + 1;
                } else {
                    result.append(input.charAt(i));
                    i++;
                }

            } else {
                result.append(input.charAt(i));
                i++;
            }
        }
        return result.toString().replace("!MY010MY!", "`$`").replace("!!MY010010MY!!","`$$`");
    }
    public static String replaceBrackets(String input) {
        if (input == null || input.isEmpty()) {
            return input;
        }
        String result = replaceMathDelimiters(input);
        result = replaceString(result);
        return result;
    }

    public static void main(String[] args) {
//        List<String> t = Arrays.asList("$$dddddddae  d \facdddddd$$","$dddddddae  d \facdddddd$","$dddddddae  d \facdddddd","$$dddddddae  d \facdddddd");
//        Pattern RE = Pattern.compile("(?<!\\$)\\$([^$]+)\\$(?!\\$)");
//        t.forEach(i ->{
//            Matcher matcher = RE.matcher(i);
//            boolean n = matcher.find();
//            System.out.println(i+"->"+n);
//
//        });
        String t = replaceBrackets("### 练习1\\n\\n#### (1) 经过多久后两人第一次相遇？\\n\\n设两人第一次相遇所需时间为 \\\\( t \\\\) 秒。由于大强和小强背向而行，他们的相对速度是他们速度的和，即 \\\\( 6 \\\\text{ 米/秒} + 4 \\\\text{ 米/秒} = 10 \\\\text{ 米/秒} \\\\)。他们相遇时，两人共同跑过的距离等于跑道的周长，即200米。因此，我们有方程：\\n\\n\\\\[ 10t = 200 \\\\]\\n\\n解得：\\n\\n\\\\[ t = \\\\frac{200}{10} = 20 \\\\text{ 秒} \\\\]\\n\\n#### (2) 再经过多久两人第二次相遇？\\n\\n两人第一次相遇后，他们继续背向而行，再次相遇时，他们共同跑过的距离又是一个跑道的周长，即200米。由于他们的相对速度仍然是10米/秒，我们有：\\n\\n\\\\[ 10t' = 200 \\\\]\\n\\n其中 \\\\( t' \\\\) 是从第一次相遇后到第二次相遇所需的时间。解得：\\n\\n\\\\[ t' = \\\\frac{200}{10} = 20 \\\\text{ 秒} \\\\]\\n\\n### 练习2\\n\\n甲、乙两人每跑5秒，都要停10秒休息，所以他们的实际运动周期是15秒。在每个周期内，甲跑的距离是 \\\\( 10 \\\\times 5 = 50 \\\\) 米，乙跑的距离是 \\\\( 5 \\\\times 5 = 25 \\\\) 米。两人每周期共同跑过的距离是 \\\\( 50 + 25 = 75 \\\\) 米。\\n\\n设两人第一次相遇所需周期数为 \\\\( n \\\\)。由于A、B两点相距100米，两人相遇时，他们共同跑过的距离加上A、B两点之间的距离应该等于跑道的周长，即400米。因此，我们有方程：\\n\\n\\\\[ 75n + 100 = 400 \\\\]\\n\\n解得：\\n\\n\\\\[ 75n = 300 \\\\]\\n\\\\[ n = \\\\frac{300}{75} = 4 \\\\]\\n\\n所以，甲、乙两人需要4个周期才能第一次相遇。每个周期是15秒，所以总时间是：\\n\\n\\\\[ 4 \\\\times 15 = 60 \\\\text{ 秒} \\\\]");
        System.out.println(t);
    }
}
