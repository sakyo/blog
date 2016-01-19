title: PriorityQueue优先队列
date: 2016-01-19
tags: [算法,leetcode]
categories: [算法]
---

今天在做Leetcode的时候，遇到了这道题，[Find Median from Data Stream](https://leetcode.com/problems/find-median-from-data-stream/)，题目不是很难，需要你构建一个类，这个类有两个操作，addNum和findMedian，分别是增加一个数据和找出已增加的这些数据的中位中数，如果中位数是两个，就取这个数的平均值。测试用例调用的方式是随机的调用这两个函数，类似从一个数据流中不停的读取数字，然后验证中位数输入是否正确。
刚开始的想法很简单，在这个类中维护一个数组，保存已输入数据，在addNum的时候，使用插入排序，保证缓存的数据流的有序性，findMedian就判断数据长度，然后输出中间的一个数或者两个数的平均值。使用Jprofie看了耗时的操作，放弃了ArrayList，使用int数组维护缓存数据流，代码如下
```
public class MedianFinder {

    // 长度
    private int size = 0;

    // 数据，hack了测试用例，知道6w是够的
    private int[] data = new int[60002];

    // Adds a number into the data structure.
    public void addNum(int num) {
        if (size == 0)
            data[0] = num;
        else
            add(insert(0, size - 1, num), num);
        size++;
    }

    // Returns the median of current data stream
    public double findMedian() {
        int pos = size / 2;
        if (size % 2 == 0)
            return (data[pos] + data[pos - 1]) / 2.0;
        else
            return data[pos];
    }

    // 二分查找插入
    public int insert(int start, int end, int num) {
        if (start >= end)
            return num > data[start] ? start + 1 : start;
        int pos = (start + end) / 2;
        if (num == data[pos])
            return pos;
        if (num < data[pos])
            return insert(start, pos - 1, num);
        return insert(pos + 1, end, num);
    }

    // 模拟数组插入操作
    private void add(int pos, int num) {
        if (pos == size) {
            data[size] = num;
        } else {
            System.arraycopy(data, pos, data, pos + 1,
                    size - pos);
            data[pos] = num;
        }
    }
}

```
提交后，发现虽然都通过了，但是性能排名惨不忍睹，只打败了13%的人，肯定是算法出了问题，纵观这道题，出问题的地方只可能完全排序这个点，大家知道，对于给定的数组，求中位数是不需要完全排序的。思考没有结果，看了论坛上对于这道题的解法，最简洁的解法，使用了JDK的优先队列PriorityQueue，维护一大一小，两个优先队列，在addNum每次读取一个数字的时候，1）先把这个数字入了大数队列，然后从大数队列里面取最小值，放入小数队列。2）当大数队列的长度小于小数队列时，从小数队列取一个最大值放入大数队列里面。这样，只需要维护大数队列和小数队列的最值，就可以省略对全部数据进行完全排序计算耗时，这里最精妙的就是使用了JDK1.5之后提供的优先队列PriorityQueue。把问题简化，分两个入口来看PriorityQueue的实现，offer()和poll()
```
public boolean offer(E e) {
    if (e == null)
        throw new NullPointerException();
    modCount++;
    int i = size;
    if (i >= queue.length)
        grow(i + 1);
    size = i + 1;
    if (i == 0)
        queue[0] = e;
    else
        siftUp(i, e);
    return true;
}
```
入队列之前，grow()判断队列长度是否需要扩展，然后进入siftUp()的偏移操作，里面对于队列元素是否实现自定义的比较，我们略过，直接看偏移操作部分
```
private void siftUpComparable(int k, E x) {
    Comparable<? super E> key = (Comparable<? super E>) x;
    while (k > 0) {
        int parent = (k - 1) >>> 1;
        Object e = queue[parent];
        if (key.compareTo((E) e) >= 0)
            break;
        queue[k] = e;
        k = parent;
    }
    queue[k] = key;
}
```
这里使用了完全二叉树，以类似从根节点到叶子节点的一层层的方式存放在队列中，这样每一个叶子节点K的父节点下坐标都是(K-1)/2,而且保证每一个根节点都小于等于他的叶子节点。如果所示,存储的顺序是1-7![完全二叉树](/img/btree.png)
首先把需要入队列的数据放到最底层的叶子，也就是队列的末尾，然后循环往上找到这个叶子的父节点，是否大于自己，如果大于自己，则交换节点，最终到达自己所在的根节点。这样就做到不改变树结构的前提下，插入队列。每次入队列都相当于在铺叶子，时间复杂度lgN。
再看一下poll()操作,获取数据很简单，就是取树的根节点即可，就是queen[0],然后就是树的下移调整，参数k是0，代表根节点下移，x是队列末尾的元素。
```
private void siftDownComparable(int k, E x) {
    Comparable<? super E> key = (Comparable<? super E>)x;
    int half = size >>> 1;        // loop while a non-leaf
    while (k < half) {
        int child = (k << 1) + 1; // assume left child is least
        Object c = queue[child];
        int right = child + 1;
        if (right < size &&
            ((Comparable<? super E>) c).compareTo((E) queue[right]) > 0)
            c = queue[child = right];
        if (key.compareTo((E) c) <= 0)
            break;
        queue[k] = c;
        k = child;
    }
    queue[k] = key;
}
```
k<half代表所有有叶子的树节点（这一点计算太巧妙了）,每一层循环，都取出这个节点的左节点值c和右节点queue[right]作比较，取出里面最小的，值赋为c，然后下坐标为child。最后比较需要移动到的位置key的值是否比c小，如果小，最后互换位置，偏移结束。循环看起来比较复杂，我们用递归的想法来描述，就是我们想移走某个根节点，就把这个跟节点一直设置为他左右节点中最小的那个，一层层往下走，直到被换的这个节点值，小于待比较的x。把最终走到的节点值设置为x，然后移除末尾的叶子即可（其实没有移除，只是设置了size的值小于一）。这里即使待比较的x和我们往下走不是一个路线也没有关系，因为这个二叉树只满足根节点小于父节点，而不会在意左右节点间的关系，所以我们那怕拿x去设置到另外一个子树也满足这个要求。
分析完优先队列之后，我重新写了那道题的答案，代码入下：
