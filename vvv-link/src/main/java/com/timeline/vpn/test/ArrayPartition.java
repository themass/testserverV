package vpn.test;//package com.timeline.vpn.test;
//
//import java.util.Arrays;
//import java.util.Comparator;
//
//public class ArrayPartition {
//
//    public static void main(String[] args) {
//        Integer[] arr = {8, 12, 15, 5, 10, 30, 18};
//        Arrays.sort(arr, new MyComparator());
//        int x = 6;
//        int y =2 ;
//        y +=x;
//        System.out.println(y);
//        System.out.println(Arrays.toString(arr));
//    }
//
//    static class MyComparator<Integer> implements Comparator<Integer> {
//        @Override
//        public int compare(Integer a, Integer b) {
//            // 按照规则比较，如果 a 能整除 b，那么 a 在 b 前面
//            if ((int)a % (int)b == 0) {
//                return -1;
//            }
//            // 否则按照正常顺序排列
//            return (int)a - (int)b;
//        }
//    }
//}