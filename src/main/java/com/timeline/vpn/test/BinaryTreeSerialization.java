package com.timeline.vpn.test;

import java.util.Arrays;
import java.util.LinkedList;
import java.util.Queue;

class TreeNode {
    int val;
    TreeNode left;
    TreeNode right;

    TreeNode(int val) {
        this.val = val;
    }
}

public class BinaryTreeSerialization {
    public String serialize(TreeNode root) {
        if (root == null) {
            return "#";
        }

        String leftSerialized = serialize(root.left);
        String rightSerialized = serialize(root.right);

        return root.val + "," + leftSerialized + "," + rightSerialized;
    }

    public TreeNode deserialize(String data) {
        Queue<String> nodes = new LinkedList<>(Arrays.asList(data.split(",")));
        return deserializeHelper(nodes);
    }

    private TreeNode deserializeHelper(Queue<String> nodes) {
        String val = nodes.poll();
        if (val.equals("#")) {
            return null;
        }

        TreeNode node = new TreeNode(Integer.parseInt(val));
        node.left = deserializeHelper(nodes);
        node.right = deserializeHelper(nodes);

        return node;
    }

    public static void main(String[] args) {
        BinaryTreeSerialization serializer = new BinaryTreeSerialization();

        // 示例二叉树: 1 -> 2 -> 3 -> null, null, 4 -> 5 -> null, null, null, null
        TreeNode root = new TreeNode(1);
        root.left = new TreeNode(2);
        root.right = new TreeNode(3);
        root.right.left = new TreeNode(4);
        root.right.left.left = new TreeNode(5);

        String serializedTree = serializer.serialize(root);
        System.out.println(serializedTree);  // 输出: "1,2,#,#,3,#,4,5,#,#,#,#"

        TreeNode deserializedTree = serializer.deserialize(serializedTree);
    }
}
