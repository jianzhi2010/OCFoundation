# NotificationCenter

### 需要注意

* 线程安全问题：不同线程添加通知、发送通知、移除通知的问题
* 监听对象可能被释放的问题
* 多次监听同一事件，会收到多次通知，需要选择好数据结构
* 监听事件名可为空，当监听事件名称传空时，可监听app中所有的通知


### 参考

* [NSNotificationCenter 实现](https://github.com/gnustep/libs-base/blob/master/Source/NSNotificationCenter.m)

