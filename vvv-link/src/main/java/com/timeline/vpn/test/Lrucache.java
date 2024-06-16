package com.timeline.vpn.test;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedList;


public class Lrucache<K,V> {
    private HashMap<K,Node> cache = new HashMap<>();
    LinkedHashMap map ;
    LinkedList list;
    private Node head;
    private Node tail;
    private int maxSize = 0;
    private int currentSize = 0;
    public Lrucache(int size){
        if(size<1){
            throw new RuntimeException("size 必须大于1");
        }
        maxSize = size;
        head = new Node();
        tail = new Node();
        head.next = tail;
        tail.pre = head;
    }
    public V getData(K key){
        Node node=  cache.get(key);
        if(node!=null){
            // remove， 放到列表头 add
            removeNode(node);
            addToHead(node);
            return node.val;
        }
        return null;
    }
    public boolean put(K key, V val){
        Node node=  cache.get(key);
        if(node!=null){
            node.val=val;
            removeNode(node);
            addToHead(node);
        }else{
            node = new Node();
            node.key=key;
            node.val=val;
            cache.put(key,node);
            // 放到列表头，add
            tryToAddNode(node);
        }
        return true;
    }
    private Node tryToAddNode(Node node){
        addToHead(node);
        if(currentSize>maxSize){
            removeNode(tail.pre);
        }
        return node;
    }
    private Node removeNode(Node node){
        node.pre.next = node.next;
        node.next.pre = node.pre;
        currentSize--;
        return node;
    }
    private Node addToHead(Node node){
        currentSize++;
        node.next = head.next;
        node.pre=head;
        head.next.pre = node;
        head.next = node;
        return node;
    }

    class Node{
        public K key;
        public V val;
        public Node pre = null;
        public Node next = null;
    }
    public static void main(String[] args) {

    }
}
