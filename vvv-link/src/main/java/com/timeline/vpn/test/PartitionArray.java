package vpn.test;

public class PartitionArray {
    public int minPartitionDifference(int[] nums) {
        int totalSum = 0;
        for (int num : nums) {
            totalSum += num;
        }

        // 如果总和是奇数，无法分割成两个等和子集
        if (totalSum % 2 != 0) {
            return -1;
        }

        int targetSum = totalSum / 2;
        int n = nums.length;

        // 创建DP数组
        boolean[][] dp = new boolean[n + 1][targetSum + 1];

        // 初始化第一列，表示和为0的情况
        for (int i = 0; i <= n; i++) {
            dp[i][0] = true;
        }

        // 填充DP数组
        for (int i = 1; i <= n; i++) {
            for (int j = 1; j <= targetSum; j++) {
                if (nums[i - 1] <= j) {
                    dp[i][j] = dp[i - 1][j] || dp[i - 1][j - nums[i - 1]];
                } else {
                    dp[i][j] = dp[i - 1][j];
                }
            }
        }

        // 找到最大的 j，使得 dp[n][j] 为 true
        int maxSum = 0;
        for (int j = targetSum; j >= 0; j--) {
            if (dp[n][j]) {
                maxSum = j;
                break;
            }
        }

        int minDifference = totalSum - 2 * maxSum;
        return minDifference;
    }

    public static void main(String[] args) {
        PartitionArray solution = new PartitionArray();

        int[] nums = {1, 6, 11, 5};

        int minDifference = solution.minPartitionDifference(nums);
        System.out.println("Minimum difference between partitions: " + minDifference);
    }
}
