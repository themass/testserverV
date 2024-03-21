package com.timeline.vpn.test;

import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;

public class TestLongStr implements Comparable{
    public static void main(String[] args) {
//        String str1 = "abcooopddddddfvxzx但是";
//        String str2 = "dadadadadaddsdddooopddddddadadada cfff";
//        int[][] dp = longStr(str1,str2);
//        for(int i=0;i<dp.length;i++) {
//            for(int j=1;j<dp[i].length;j++) {
//                System.out.print(dp[i][j]);
//            }
//            System.out.println();
//        }

//        String str1 = "bcbab";
//        int[][] dp = huiStr(str1);
//        for(int i=0;i<dp.length;i++) {
//            for(int j=0;j<dp[i].length;j++) {
//                System.out.print(dp[i][j]);
//            }
//            System.out.println();
//        }
        String str = "/a//c/c/c/c/c";
        String[] s = str.split("/");
        System.out.println(Arrays.asList(s));

    }
    public static void longgest_subString(String str1, String str2) {
        int [][] dp = new int[str1.length()+1][str2.length()+1];
        for(int i=1;i<str1.length()+1;i++){
            for(int j=1;i<str2.length()+1;j++){
                if(str1.charAt(i) == str2.charAt(j)){
                    dp[i][j] = dp[i-1][j-1]+1;
                }else{
                    dp[i][j] = Math.max(dp[i-1][j],dp[i][j-1]);
                }
            }
        }
    }
    public static void longgest_lianxu(int[] nums) {
        HashSet<Integer> hset = new HashSet<>();
        for(int num:nums){
            hset.add(num);
        }
        int max =1;
        for(int i=0;i<nums.length;i++){
            if(!hset.contains(nums[i]-1)) {
                int s = 1;
                while (hset.contains(nums[i]+s)){
                    s++;
                }
                max = Math.max(max,s);
            }

        }

    }
        public static void noRepeat(String str1) {
        char[] c1 = str1.toCharArray();
        HashMap<Character,Integer> hMap = new HashMap<Character,Integer>();
        int r = 0;
        int l = 0;
        int max=0;
        while(r<c1.length) {
            if (hMap.get(c1[r])==null) {
                hMap.put(c1[r],r);
                r++;
                max = Math.max(max,r-l+1);
            } else {
                hMap.remove(c1[l]);
                l++;
            }
        }
    }

        public static int[][] maxCommonSubstring(String str1,String str2) {
        char[] c1 = str1.toCharArray();
        char[] c2 = str2.toCharArray();
        int[][]dp = new int[c1.length+1][c2.length+1];
        for(int i=1;i<c1.length+1;i++){
            for(int j=1;j<c2.length+1;j++){
                if(c1[i-1]==c2[j-1]){
                    dp[i][j] = dp[i-1][j-1]+1;
                }
                
            }
        }
        return dp;
    }
        public static int[][] huiStr(String str1){
        int n = str1.toCharArray().length;
        char[] c1 = str1.toCharArray();
        int[][] dp=  new int[n][n];
        for(int i=0;i<n;i++){
            dp[i][i] = 1;
        }
        for(int i=n-1;i>=0;i--){
            for(int j=i+1;j<n;j++){
                if(c1[i]==c1[j]){
                    dp[i][j] =  dp[i+1][j-1]+2;
                }else{
                    dp[i][j] = Math.max(dp[i+1][j],dp[i][j-1]);
                }
            }
        }
       return dp;
    }
    public static int[] maxPriceGupiao(int[] buyPrice,int[] maiPrice) {
        int n = buyPrice.length;
        int[] dp = new int[n];
        int minBuy = buyPrice[0];
        int maxPrice = 0;
        for(int i=1;i<n;i++){
            minBuy = Math.min(minBuy,buyPrice[i]);
            maxPrice = Math.max(maxPrice,maiPrice[i] - minBuy);
            dp[i] = maxPrice;
        }
        return dp;
    }
        public static int[] coinChange(int[] coins,int amount) {
        int[]dp = new int[amount+1];
        dp[0]=0;
        for(int i=1;i<amount+1;i++){
            int min = Integer.MAX_VALUE;
            for(int c:coins){
                if(c<i) {
                    min = Math.min(min, dp[i - c] + 1);
                }
            }
            dp[i] = min;
        }
        return dp;
    }
        public static int[] maxPricegangjin(int n,int[]p){
        int[] dp = new int[n+1];
        dp[0] = 0;
        for(int i=1;i<=n;i++){
            int max = 0;
            for(int j=0;j<=i;j++){
                max = Math.max(p[i-j]+dp[j],max);
            }
            dp[i] = max;
        }
        return dp;
    }
        public static int[][] longStr(String str1,String str2){
        char[] c1 = str1.toCharArray();
        char[] c2 = str2.toCharArray();
        int[][] dp=  new int[c1.length+1][c2.length+1];
        for(int i=1;i<c1.length+1;i++){
            for(int j=1;j<c2.length+1;j++){
                if(c1[i-1] == c2[j-1]){
                    dp[i][j] = dp[i-1][j-1]+1;
                }else{
                    dp[i][j] = Math.max(dp[i-1][j],dp[i][j-1]);
                }
            }
        }
        return dp;
    }

    @Override
    public int compareTo(Object o) {
        return 0;
    }
}
