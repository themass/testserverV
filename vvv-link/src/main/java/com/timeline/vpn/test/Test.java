package com.timeline.vpn.test;

import java.util.concurrent.Executor;

class Node{
    public Node next;
    public int val;
    public Node(int val){
        this.val = val;
    }
}
public class Test {
    Executor e = null;

    public int findHead(Node node){
        Node slow = node.next;
        Node fast = node.next.next;
        Node second = node.next;
        Node findPos = node;
        int pos=0;
        while(slow != fast && fast != null && fast.next != null){
            slow = slow.next;
            fast = fast.next.next;
        }
       if(fast.next == null) {  //无环
           return -1;
       }
//       while (second != slow){ //找到头结点
//           second = second.next;
//           slow = slow.next;
//       }
        System.out.println(slow.val);
        while (findPos != slow){ //走过的步骤就是 pos
            findPos = findPos.next;
            slow = slow.next;
            pos++;
        }
        return pos;
    }

    public static void main(String[] args) {
        Node l1 = new Node(1);
        l1.next = new Node(2);
        l1.next.next = new Node(3);
        l1.next.next.next = new Node(4);
        l1.next.next.next.next = new Node(5);
        l1.next.next.next.next.next = new Node(6);
        l1.next.next.next.next.next.next = new Node(7);
        l1.next.next.next.next.next.next.next = l1.next.next.next.next;
        Test test = new Test();
        int pos = test.findHead(l1);
        System.out.println(pos);
    }

}
