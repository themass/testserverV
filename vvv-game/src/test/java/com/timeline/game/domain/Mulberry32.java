package com.timeline.game.domain;

/** 测试专用的确定性随机源（mulberry32），镜像 TS test/helpers.ts。 */
final class Mulberry32 {

    private Mulberry32() {}

    /** JS 的 int 溢出回绕 = Java int 乘法/加法回绕；唯一的无符号点在最后的 >>> 0 / toUnsignedLong。 */
    static java.util.function.DoubleSupplier of(int seed) {
        int[] a = {seed};
        return () -> {
            a[0] = a[0] + 0x6D2B79F5;
            int t = a[0];
            // t = Math.imul(t ^ (t >>> 15), t | 1)：两个操作数都读同一个旧 t，Java 赋值前求值语义一致
            t = (t ^ (t >>> 15)) * (t | 1);
            t ^= t + (t ^ (t >>> 7)) * (t | 61);
            return Integer.toUnsignedLong(t ^ (t >>> 14)) / 4294967296.0;
        };
    }
}
