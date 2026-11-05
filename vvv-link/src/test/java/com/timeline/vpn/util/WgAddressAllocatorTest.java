package com.timeline.vpn.util;

import org.junit.jupiter.api.Assertions;
import org.junit.jupiter.api.Test;

import java.util.HashMap;
import java.util.Map;
import java.util.TreeMap;

class WgAddressAllocatorTest {

    /** 内存版存储，行为与数据库一致：devId、addrIndex 都唯一；nextFreeIndex 取最小空闲值。 */
    private static class FakeStore implements WgAddressAllocator.Store {
        final Map<String, Integer> index = new HashMap<>();
        final Map<String, String> keys = new HashMap<>();
        final Map<String, String> owners = new HashMap<>();
        final int min;
        final int max;
        /** 在第一次 tryInsert 之前，模拟另一个请求抢先占用的下标。 */
        Integer stealBeforeFirstInsert;
        int insertCalls;

        FakeStore(int min, int max) {
            this.min = min;
            this.max = max;
        }

        @Override
        public Integer findIndex(String devId) {
            return index.get(devId);
        }

        @Override
        public void updateKey(String devId, String publicKey, String userName) {
            owners.put(devId, userName);
            keys.put(devId, publicKey);
        }

        @Override
        public boolean tryInsert(String devId, String publicKey, String userName, int i) {
            owners.put(devId, userName);
            insertCalls++;
            if (stealBeforeFirstInsert != null) {
                index.put("someone-else", stealBeforeFirstInsert);
                stealBeforeFirstInsert = null;
            }
            if (index.containsKey(devId) || index.containsValue(i)) {
                return false;
            }
            index.put(devId, i);
            keys.put(devId, publicKey);
            return true;
        }

        @Override
        public Integer nextFreeIndex() {
            for (int i = min; i <= max; i++) {
                if (!index.containsValue(i)) {
                    return i;
                }
            }
            return null;
        }
    }

    @Test
    void newDevicesGetConsecutiveDistinctIndexes() {
        FakeStore store = new FakeStore(2, 100);
        WgAddressAllocator a = new WgAddressAllocator(store);
        Assertions.assertEquals(2, a.register("d1", "K1=", "alice"));
        Assertions.assertEquals(3, a.register("d2", "K2=", "alice"));
        Assertions.assertEquals(4, a.register("d3", "K3=", "alice"));
    }

    @Test
    void reRegisteringKeepsTheAddressAndReplacesTheKey() {
        FakeStore store = new FakeStore(2, 100);
        WgAddressAllocator a = new WgAddressAllocator(store);
        int first = a.register("d1", "OLD=", "alice");
        a.register("d2", "K2=", "alice");
        Assertions.assertEquals(first, a.register("d1", "NEW=", "alice"), "重装 App 后地址必须不变");
        Assertions.assertEquals("NEW=", store.keys.get("d1"));
        Assertions.assertEquals(2, store.index.size(), "不能因为重复注册多占一个地址");
    }

    @Test
    void retriesWhenTheFreeIndexWasTakenByAConcurrentRequest() {
        FakeStore store = new FakeStore(2, 100);
        store.stealBeforeFirstInsert = 2;
        WgAddressAllocator a = new WgAddressAllocator(store);
        Assertions.assertEquals(3, a.register("d1", "K1=", "alice"), "下标 2 被抢走后应换下一个空闲的");
        Assertions.assertEquals(2, store.insertCalls);
    }

    @Test
    void reusesAGapLeftByADeletedDevice() {
        FakeStore store = new FakeStore(2, 100);
        WgAddressAllocator a = new WgAddressAllocator(store);
        a.register("d1", "K1=", "alice");
        a.register("d2", "K2=", "alice");
        a.register("d3", "K3=", "alice");
        store.index.remove("d2");
        Assertions.assertEquals(3, a.register("d4", "K4=", "alice"));
    }

    @Test
    void exhaustedPoolIsReportedNotWrappedAround() {
        FakeStore store = new FakeStore(2, 3);
        WgAddressAllocator a = new WgAddressAllocator(store);
        a.register("d1", "K1=", "alice");
        a.register("d2", "K2=", "alice");
        Assertions.assertThrows(WgAddressAllocator.PoolExhaustedException.class, () -> a.register("d3", "K3=", "alice"));
        // 已注册的设备在池满后仍然可以更新公钥
        Assertions.assertEquals(2, a.register("d1", "K1b=", "alice"));
    }

    @Test
    void giveUpWithAClearErrorWhenConflictsNeverStop() {
        FakeStore store = new FakeStore(2, 100) {
            @Override
            public boolean tryInsert(String devId, String publicKey, String userName, int i) {
            owners.put(devId, userName);
                return false;
            }
        };
        Assertions.assertThrows(IllegalStateException.class, () -> new WgAddressAllocator(store).register("d1", "K1=", "alice"));
    }

    @Test
    void allocatedIndexesAreUniqueAcrossManyDevices() {
        FakeStore store = new FakeStore(2, 1000);
        WgAddressAllocator a = new WgAddressAllocator(store);
        Map<Integer, String> seen = new TreeMap<>();
        for (int i = 0; i < 500; i++) {
            int idx = a.register("dev" + i, "K" + i + "=", "alice");
            Assertions.assertNull(seen.put(idx, "dev" + i), "地址重复分配: " + idx);
        }
    }
}
