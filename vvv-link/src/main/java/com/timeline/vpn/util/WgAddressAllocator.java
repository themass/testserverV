package com.timeline.vpn.util;

/**
 * 给设备分配 WireGuard 地址（addrIndex）。
 * <p>
 * 与存储解耦，方便不起 Spring 和数据库就测并发冲突路径。两台设备同时注册时可能拿到同一个空闲下标，
 * 数据库的唯一键会让其中一个插入失败，这里重新取下标再试；同一台设备并发注册则以先插入成功的为准。
 */
public final class WgAddressAllocator {

    private static final int MAX_ATTEMPTS = 8;

    /** 地址池用完（约 6.5 万台设备）。 */
    public static final class PoolExhaustedException extends RuntimeException {
        private static final long serialVersionUID = 1L;

        public PoolExhaustedException() {
            super("WireGuard 地址池已用完");
        }
    }

    public interface Store {
        /** 设备已有的 addrIndex，没有返回 null。 */
        Integer findIndex(String devId);

        void updateKey(String devId, String publicKey, String userName);

        /** 插入新设备；addrIndex 或 devId 唯一键冲突返回 false，其他错误直接抛。 */
        boolean tryInsert(String devId, String publicKey, String userName, int index);

        /** 当前最小的空闲 addrIndex（范围 INDEX_MIN ~ INDEX_MAX），池满返回 null。 */
        Integer nextFreeIndex();
    }

    private final Store store;

    public WgAddressAllocator(Store store) {
        this.store = store;
    }

    /**
     * 注册设备公钥并返回该设备的 addrIndex。重复注册覆盖公钥，地址保持不变（客户端重装后拿到同一个地址）。
     */
    public int register(String devId, String publicKey, String userName) {
        for (int attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
            Integer existing = store.findIndex(devId);
            if (existing != null) {
                store.updateKey(devId, publicKey, userName);
                return existing;
            }
            Integer free = store.nextFreeIndex();
            if (free == null) {
                throw new PoolExhaustedException();
            }
            if (store.tryInsert(devId, publicKey, userName, free)) {
                return free;
            }
            // 下标被别人抢先占了，或同一设备被并发注册：回到循环开头重新判断。
        }
        throw new IllegalStateException("WireGuard 地址分配冲突过多，请重试");
    }
}
