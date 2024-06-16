package com.timeline.vpn.test;

public class CoinChange {

    public static int change(int amount, int[] coins) {
        int[] dp = new int[amount + 1];
        dp[0] = 1;

        for (int coin : coins) {
            for (int i = coin; i <= amount; i++) {
                System.out.println(dp[i]);
                dp[i] += dp[i - coin];
            }
        }

        return dp[amount];
    }

    public static void main(String[] args) {
        int amount = 5;
        int[] coins = {1, 2, 5};
        int result = change(amount, coins);
        System.out.println("Total combinations: " + result);
    }
}
