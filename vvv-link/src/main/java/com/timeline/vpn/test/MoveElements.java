package vpn.test;

public class MoveElements {

    public static void moveElements(int[] nums) {
        int low = 0;
        int high = nums.length - 1;

        while (low <= high) {
            if (nums[low] == 1) {
                low++;
            } else if (nums[low] == 0) {
                low++;
            } else {  // nums[low] == -1
                swap(nums, low, high);
                high--;
            }
        }
    }

    private static void swap(int[] nums, int i, int j) {
        int temp = nums[i];
        nums[i] = nums[j];
        nums[j] = temp;
    }

    public static void main(String[] args) {
        // 示例
        int[] arr = {-1, 0, 1, 1, 0, -1, 0, 1};
        moveElements(arr);

        // 输出结果
        for (int num : arr) {
            System.out.print(num + " ");
        }
    }
}
