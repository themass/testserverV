package com.timeline.vpn.test;

class ListNode {
    int val;
    ListNode next;

    ListNode(int val) {
        this.val = val;
    }
}

public class RightAlignAddition {

    public ListNode addTwoNumbers(ListNode l1, ListNode l2) {
        int len1 = getLength(l1);
        int len2 = getLength(l2);

        // 补齐短链表前面的节点
        if (len1 < len2) {
            l1 = padZeros(l1, len2 - len1);
        } else {
            l2 = padZeros(l2, len1 - len2);
        }

        // 递归地相加
        int carry = addLists(l1, l2);

        // 如果有进位，创建新的头节点
        if (carry > 0) {
            ListNode result = new ListNode(carry);
            result.next = l1;
            return result;
        }

        return l1;
    }

    private int getLength(ListNode l) {
        int length = 0;
        while (l != null) {
            length++;
            l = l.next;
        }
        return length;
    }

    private ListNode padZeros(ListNode l, int count) {
        ListNode head = l;
        for (int i = 0; i < count; i++) {
            ListNode zero = new ListNode(0);
            zero.next = head;
            head = zero;
        }
        return head;
    }

    private int addLists(ListNode l1, ListNode l2) {
        if (l1 == null) {
            return 0;
        }

        int carry =  addLists(l1.next, l2.next);

        // 更新当前节点的值和进位
        carry  = l1.val + l2.val + carry;
        l1.val = carry % 10;
        return carry / 10;
    }

    public static void main(String[] args) {
        // 示例
        // l1: 1 -> 2 -> 3
        // l2: 4 -> 5 -> 6
        ListNode l1 = new ListNode(6);
        l1.next = new ListNode(4);
        l1.next.next = new ListNode(8);

        ListNode l2 = new ListNode(4);
        l2.next = new ListNode(5);
        l2.next.next = new ListNode(6);

        RightAlignAddition rightAlignAddition = new RightAlignAddition();
        ListNode result = rightAlignAddition.addTwoNumbers(l1, l2);

        // 输出结果
        while (result != null) {
            System.out.print(result.val + " ");
            result = result.next;
        }
    }
}
