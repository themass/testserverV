package com.timeline.vpn.photosolve;

import java.util.ArrayDeque;
import java.util.Deque;

/**
 * 把被 {@code max_tokens} 砍断的 JSON 补成合法 JSON。
 *
 * <h3>为什么需要</h3>
 * 豆包输出顶到 maxTokens 会硬截断，{@link DoubaoPhotoSolveProvider#extractJson} 要求括号配平，
 * 于是返回 null。以前这条路径直接 {@code questionFound=false} → 客户端 40002「不是题目」；
 * 改成兜底纯文本以后，用户至少能看到内容，但看到的是<b>一整坨没解析的 JSON 源码</b>——
 * 题干、答案、步骤这些结构全丢了。这里把「已经写完整的那部分」还原成结构。
 *
 * <h3>唯一的判据：一个字都不编</h3>
 * <ul>
 *   <li>截断落在字符串<b>值</b>里：保留已吐出的内容并补收尾引号（半句话仍然是内容）；</li>
 *   <li>截断落在<b>数字 / true / false / null</b> 里：整个成员丢掉——半个数字是<b>错值</b>，
 *       比不给更糟（{@code "score":1} 可能是 1，也可能是 12、128）；</li>
 *   <li>截断落在<b>键名</b>里、或停在 {@code "k":} 之后值还没开始：这个成员丢掉；</li>
 *   <li>其余只允许在末尾追加收尾符 {@code " } ]}。不重排、不改写已写出的字节。</li>
 * </ul>
 *
 * 末尾孤立的一个反斜杠（截断正好停在 {@code \f} 的 {@code \} 上）会被去掉再补引号，
 * 否则补出去的引号会被它转义，整包又坏了。
 *
 * <h3>不校验语义</h3>
 * 这里只做括号与字符串配平，不校验 JSON 之外的约定。救出来的结构交给
 * {@link PhotoSolveJsonRepair}（反斜杠）+ Jackson，字段缺失由调用方按「没有该字段」处理。
 */
public final class PhotoSolveJsonSalvage {

    private static final int OBJECT = 0;
    private static final int ARRAY = 1;

    /** 容器内的解析位置。 */
    private static final int EXPECT_ITEM = 0;
    private static final int EXPECT_COLON = 1;
    private static final int EXPECT_VALUE = 2;
    private static final int AFTER_VALUE = 3;
    /** 正在读一个裸字面量（数字 / true / false / null）；到 EOF 仍在此状态说明它被截断。 */
    private static final int IN_LITERAL = 4;

    /** 一个打开中的容器。 */
    private static final class Frame {
        final int type;
        /** 当前成员的起始下标；-1 表示这个容器里还没有成员开始（刚开容器或刚过逗号）。 */
        int itemStart = -1;
        /** 截断时丢掉 itemStart 起的成员后，要补的收尾串（快照于该成员开始的那一刻）。 */
        String itemClosers = "";

        Frame(int type) {
            this.type = type;
        }
    }

    private PhotoSolveJsonSalvage() {
    }

    /**
     * @param raw 模型原文，可能被截断，也可能带 ``` 围栏或前置说明文字
     * @return 补好的 JSON 文本；连一个 {@code {} 都没有时返回 null（那是真的没吐 JSON）
     */
    public static String salvage(String raw) {
        if (raw == null) {
            return null;
        }
        int begin = raw.indexOf('{');
        if (begin < 0) {
            return null;
        }

        Deque<Frame> stack = new ArrayDeque<>();
        Frame root = new Frame(OBJECT);
        root.itemStart = begin + 1;
        root.itemClosers = "}";
        stack.push(root);

        int state = EXPECT_ITEM;
        boolean inString = false;
        boolean stringIsKey = false;
        boolean escaped = false;
        int n = raw.length();

        for (int i = begin + 1; i < n; i++) {
            char c = raw.charAt(i);

            if (inString) {
                if (escaped) {
                    escaped = false;
                } else if (c == '\\') {
                    escaped = true;
                } else if (c == '"') {
                    inString = false;
                    state = stringIsKey ? EXPECT_COLON : AFTER_VALUE;
                }
                continue;
            }

            if (state == IN_LITERAL && !isLiteralChar(c)) {
                // 裸字面量被合法分隔符结束，说明它是完整的；这个字符本身还要继续按结构处理
                state = AFTER_VALUE;
            }

            Frame top = stack.peek();

            if (c == '"') {
                if (top.type == OBJECT && state == EXPECT_ITEM) {
                    markItemStart(stack, top, i);
                    stringIsKey = true;
                } else {
                    if (top.type == ARRAY) {
                        markItemStart(stack, top, i);
                    }
                    stringIsKey = false;
                }
                inString = true;
                continue;
            }

            if (isWhitespace(c)) {
                continue;
            }

            switch (c) {
                case '{':
                case '[': {
                    // 容器本身作为成员：它一旦被截断也是「保留已写出的内容再收尾」，
                    // 不会被整块丢弃，所以不占用父容器的 itemStart 语义。
                    Frame f = new Frame(c == '{' ? OBJECT : ARRAY);
                    stack.push(f);
                    f.itemStart = i + 1;
                    f.itemClosers = closersOf(stack);
                    state = EXPECT_ITEM;
                    continue;
                }
                case '}':
                case ']': {
                    boolean match = (c == '}' && top.type == OBJECT) || (c == ']' && top.type == ARRAY);
                    if (!match) {
                        // 模型自己写坏了：忽略这个符号，不让它把外层容器提前关掉
                        continue;
                    }
                    stack.pop();
                    if (stack.isEmpty()) {
                        // 括号已经配平：后半段（如果有）与本次无关
                        return raw.substring(begin, i + 1);
                    }
                    state = AFTER_VALUE;
                    continue;
                }
                case ':':
                    if (state == EXPECT_COLON) {
                        state = EXPECT_VALUE;
                    }
                    continue;
                case ',':
                    // 下一个成员从头开始记
                    top.itemStart = -1;
                    state = EXPECT_ITEM;
                    continue;
                default:
                    if (top.type == ARRAY && (state == EXPECT_ITEM || state == EXPECT_VALUE)) {
                        markItemStart(stack, top, i);
                        state = IN_LITERAL;
                    } else if (top.type == OBJECT && state == EXPECT_VALUE) {
                        // 键已经记过 itemStart，值不再覆盖它
                        state = IN_LITERAL;
                    }
                    continue;
            }
        }

        // ---- 走到这里说明括号没配平：按截断位置收尾 ----
        StringBuilder out = new StringBuilder(n + 8);
        String closers;

        if (inString && !stringIsKey) {
            // 截断在字符串值里：内容照收，补上收尾引号
            out.append(raw, begin, n);
            if (escaped) {
                // 末尾孤立的反斜杠会把补出去的引号转义掉，先去掉它
                int last = out.length() - 1;
                if (last >= 0 && out.charAt(last) == '\\') {
                    out.setLength(last);
                }
            }
            out.append('"');
            closers = closersOf(stack);
        } else if (inString || state == IN_LITERAL || state == EXPECT_COLON || state == EXPECT_VALUE) {
            // 键名截断 / 值没开始 / 裸字面量截断：整个成员丢掉
            Frame top = stack.peek();
            int cut = top.itemStart < 0 ? begin + 1 : top.itemStart;
            out.append(raw, begin, Math.max(begin + 1, cut));
            closers = top.itemClosers.isEmpty() ? closersOf(stack) : top.itemClosers;
        } else {
            // 正好停在成员边界：已写出的全部保留
            out.append(raw, begin, n);
            closers = closersOf(stack);
        }

        stripTrailingComma(out);
        out.append(closers);
        return out.toString();
    }

    private static void markItemStart(Deque<Frame> stack, Frame top, int index) {
        if (top.itemStart < 0) {
            top.itemStart = index;
            top.itemClosers = closersOf(stack);
        }
    }

    /** 由内到外每个打开容器的收尾符（栈从栈顶=最内层开始迭代，正是要的收尾顺序）。 */
    private static String closersOf(Deque<Frame> stack) {
        StringBuilder sb = new StringBuilder(stack.size());
        for (Frame f : stack) {
            sb.append(f.type == OBJECT ? '}' : ']');
        }
        return sb.toString();
    }

    /** 砍在成员中间时，前面那个分隔逗号必须去掉，否则补完是 {@code [1,]} 这种非法写法。 */
    private static void stripTrailingComma(StringBuilder sb) {
        int end = sb.length();
        while (end > 0 && isWhitespace(sb.charAt(end - 1))) {
            end--;
        }
        if (end > 0 && sb.charAt(end - 1) == ',') {
            sb.setLength(end - 1);
        }
    }

    private static boolean isLiteralChar(char c) {
        return c != '"' && c != '{' && c != '}' && c != '[' && c != ']'
                && c != ',' && c != ':' && !isWhitespace(c);
    }

    private static boolean isWhitespace(char c) {
        return c == ' ' || c == '\t' || c == '\n' || c == '\r';
    }
}
