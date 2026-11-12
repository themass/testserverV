package com.timeline.vpn.photosolve;

import java.util.Arrays;
import java.util.HashSet;
import java.util.Set;

/**
 * 修复模型输出里 LaTeX 反斜杠和 JSON 转义的冲突。
 *
 * <h3>问题</h3>
 * 模型要在 JSON 字符串里写 {@code \frac{1}{2}}，按规范必须写成 {@code \\frac{1}{2}}。
 * 但模型经常只写一个反斜杠，结果分两种：
 * <ul>
 *   <li>{@code \sqrt}、{@code \pi}、{@code \(} 等：不是合法 JSON 转义，解析<b>直接抛异常</b>，整题退化成纯文本；</li>
 *   <li>{@code \frac}、{@code \text}、{@code \beta}、{@code \right}、{@code \neq}、{@code \nu}：
 *       恰好以 {@code \f \t \b \r \n} 开头，是合法转义，解析<b>不报错但公式被静默破坏</b>
 *       （{@code \frac} 变成「换页符 + rac」）。后一种更危险，因为没有任何异常能提醒我们。</li>
 * </ul>
 *
 * <h3>做法</h3>
 * 在 JSON 字符串内部逐字符扫描。遇到反斜杠时：
 * <ol>
 *   <li>后面是另一个反斜杠：已经正确转义，原样保留这一对；</li>
 *   <li>后面是 {@code " / u}（u 要求后跟 4 位十六进制，即 Unicode 转义）：合法 JSON 转义，保留；</li>
 *   <li>后面是 {@code b f n r t} 之一：<b>看后面的字母序列是不是已知的 LaTeX 命令</b>
 *       （{@code frac}、{@code text}、{@code right}、{@code neq}……），是就补一个反斜杠，否则当作真正的转义保留；</li>
 *   <li>后面是其他字符（{@code \( \[ \s \p \l ...}）：JSON 里非法，一定是 LaTeX，补一个反斜杠。</li>
 * </ol>
 *
 * <h3>已知的歧义</h3>
 * {@code \nu}（希腊字母 ν）与「换行 + u」、{@code \theta} 与「制表符 + heta」无法靠局部字符区分。
 * 这里按<b>最长匹配已知命令</b>处理：{@code \nu} 后面如果紧跟字母则视为命令，
 * 所以真的想写「换行后接 u 开头的单词」会被误判——这在数学题里远比反过来少见，且提示词里要求用
 * {@code \\n} 之外的方式分段（每个步骤独立成条，不依赖字符串内换行）。
 */
public final class PhotoSolveJsonRepair {

    /**
     * 以 b/f/n/r/t 开头、同时是常见 LaTeX 命令的名字。只列「会被合法转义吞掉」的那一类；
     * 其他字母开头的命令（sqrt、pi、alpha…）不需要列，它们本来就是非法转义，一律补反斜杠。
     */
    // HashSet 而不是 Set.of：Set.of 遇到重复元素会在类加载时抛 IllegalArgumentException，加命令时容易手滑
    private static final Set<String> LATEX_COMMANDS_STARTING_WITH_ESCAPE_LETTER = new HashSet<>(Arrays.asList(
            // \b...
            "beta", "bar", "begin", "big", "Big", "bigg", "Bigg", "binom", "boldsymbol", "bmod", "bot", "bullet",
            "backslash", "because", "bigcup", "bigcap", "bigoplus", "bigotimes", "bigvee", "bigwedge",
            // \f...
            "frac", "forall", "flat", "fbox", "footnotesize", "frown", "fcolorbox",
            // \n...
            "neq", "ne", "nu", "not", "notin", "nabla", "natural", "newline", "ni", "nmid", "nless", "ngtr",
            "nleq", "ngeq", "nsubseteq", "nrightarrow", "nleftarrow", "nearrow", "nwarrow", "normalsize",
            "nolimits", "nonumber", "negthickspace", "neg", "nexists", "nsim", "ncong", "nparallel",
            // \r...
            "right", "rightarrow", "Rightarrow", "rho", "rangle", "rbrace", "rbrack", "rceil", "rfloor",
            "rightleftharpoons", "rm", "root", "requiv", "restriction", "rVert", "rvert",
            // \t...
            "text", "textbf", "textit", "textrm", "textsf", "texttt", "textcolor", "tfrac", "theta",
            "tan", "tanh", "times", "to", "top", "triangle", "triangleq", "tau", "therefore", "tilde", "thickspace",
            "thinspace", "tiny", "textstyle", "tbinom", "tag", "tt"
    ));

    private PhotoSolveJsonRepair() {
    }

    /**
     * @param json 可能含错误转义的 JSON 文本
     * @return 反斜杠已修复的 JSON 文本；输入为 null 时返回 null
     */
    public static String repair(String json) {
        if (json == null || json.indexOf('\\') < 0) {
            return json;
        }
        StringBuilder out = new StringBuilder(json.length() + 16);
        boolean inString = false;
        int n = json.length();
        for (int i = 0; i < n; i++) {
            char c = json.charAt(i);
            if (!inString) {
                out.append(c);
                if (c == '"') {
                    inString = true;
                }
                continue;
            }
            if (c == '"') {
                out.append(c);
                inString = false;
                continue;
            }
            if (c != '\\') {
                out.append(c);
                continue;
            }
            // ---- 字符串内的反斜杠 ----
            if (i + 1 >= n) {
                out.append("\\\\"); // 末尾孤立的反斜杠
                continue;
            }
            char next = json.charAt(i + 1);
            if (next == '\\') {
                // 已经是正确转义。要连同第二个一起消耗，否则 \\frac 会被当成 \ + \frac 处理
                out.append("\\\\");
                i++;
            } else if (next == '"' || next == '/') {
                out.append(c).append(next);
                i++;
            } else if (next == 'u' && isHex4(json, i + 2)) {
                out.append("\\u");
                i++;
            } else if (isEscapeLetter(next)) {
                String word = readLetters(json, i + 1);
                if (LATEX_COMMANDS_STARTING_WITH_ESCAPE_LETTER.contains(word)
                        || startsWithKnownCommand(word)) {
                    out.append("\\\\"); // 是 LaTeX 命令：补一个反斜杠
                } else {
                    out.append(c).append(next); // 真正的 \n \t ...
                    i++;
                }
            } else {
                out.append("\\\\"); // 非法 JSON 转义，一定是 LaTeX
            }
        }
        return out.toString();
    }

    private static boolean isEscapeLetter(char c) {
        return c == 'b' || c == 'f' || c == 'n' || c == 'r' || c == 't';
    }

    private static boolean isHex4(String s, int from) {
        if (from + 4 > s.length()) {
            return false;
        }
        for (int i = from; i < from + 4; i++) {
            char h = s.charAt(i);
            boolean hex = (h >= '0' && h <= '9') || (h >= 'a' && h <= 'f') || (h >= 'A' && h <= 'F');
            if (!hex) {
                return false;
            }
        }
        return true;
    }

    /** 从 from 开始读连续的英文字母。 */
    private static String readLetters(String s, int from) {
        int end = from;
        while (end < s.length() && Character.isLetter(s.charAt(end)) && s.charAt(end) < 128) {
            end++;
        }
        return s.substring(from, end);
    }

    /**
     * 字母序列以已知命令开头也算命令，例如 {@code \bigl}、{@code \bigr}、{@code \textcolorred}
     * （模型把命令和后面的字母连着写）。只对长度 &gt;= 3 的命令生效，避免 {@code \to}、{@code \ne}
     * 这类短命令把 {@code \nThe}（换行后接 The）误判成公式。
     *
     * 误判面很小：word 的第一个字母就是转义字母本身（n/t/b/r/f），
     * 真正的「换行 + 文字」只有在文字恰好以某个命令的后半截开头（如 {@code \n} + {@code eg}）时才会撞上。
     */
    private static boolean startsWithKnownCommand(String word) {
        for (String cmd : LATEX_COMMANDS_STARTING_WITH_ESCAPE_LETTER) {
            if (cmd.length() >= 3 && word.startsWith(cmd)) {
                return true;
            }
        }
        return false;
    }
}
