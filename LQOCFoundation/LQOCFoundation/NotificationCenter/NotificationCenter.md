# NotificationCenter

### 需要注意

* 线程安全问题：不同线程添加通知、发送通知、移除通知的问题
* 监听对象可能被释放的问题
* 多次监听同一事件，会收到多次通知，需要选择好数据结构
* 监听事件名可为空，当监听事件名称传空时，可监听app中所有的通知
* 如果要实现在主线程发送通知的api，不要使用GCD，这样可能会导致执行顺序不一致（GCD会异步执行），建议使用 `performSelectorOnMainThread:` 并且需要判断当前是否在主线程

### 参考

* [NSNotificationCenter 实现](https://github.com/gnustep/libs-base/blob/master/Source/NSNotificationCenter.m)
* [Notification与多线程](http://southpeak.github.io/2015/03/14/nsnotification-and-multithreading/)
