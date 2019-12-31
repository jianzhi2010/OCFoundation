# Autorealrelease pool

### 作用

iOS 里面的自动释放池用于内存管理，自动释放对象

### 原理

自动释放池由很多页组成，使用双向链表结构串起来，相当于分页管理，新增自动释放对象或者新增releasePool 会判断是否需要新创建一页链接到链表后面，然后添加到每页的栈里面。

下面结合代码分析一下:

```
int main(int argc, char * argv[]) {
    //使用 autoreleasepool 关键字创建自动释放池
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}

编译后简化代码类似于：
int main(int argc, const char * argv[]) {
    {
        void * atautoreleasepoolobj = objc_autoreleasePoolPush();
        
        // do whatever you want
        
        objc_autoreleasePoolPop(atautoreleasepoolobj);
    }
    return 0;
}
```

这个 autoreleasepool 关键字的实现其实十分巧妙，push后返回该释放池的起始地址， pop的时候回到这个地址即可，中间不管有多少对象全部干掉即可。

先了解 `AutoleasePoolPage` 这个对象结构
AutoleasePoolPage 是c++的一个类，里面有parent、child指针，表明了它是一个双链表结构。（每一个自动释放池都是由一系列的 AutoreleasePoolPage 组成的）

```
class AutoreleasePoolPage {
    magic_t const magic;
    id *next;
    pthread_t const thread;
    AutoreleasePoolPage * const parent;
    AutoreleasePoolPage *child;
    uint32_t const depth;
    uint32_t hiwat;
};

```

再来细看 `objc_autoreleasePoolPush` 、`objc_autoreleasePoolPop` 的实现：

```
// autorelease 方法
 static inline id autorelease(id obj)
 {
   assert(obj);
   assert(!obj->isTaggedPointer());
   id *dest __unused = autoreleaseFast(obj);
   assert(!dest  ||  dest == EMPTY_POOL_PLACEHOLDER  ||  *dest == obj);
   return obj;
 }
....

void *objc_autoreleasePoolPush(void) {
    return AutoreleasePoolPage::push();
}

void objc_autoreleasePoolPop(void *ctxt) {
    AutoreleasePoolPage::pop(ctxt);
}

//push的核心代码
static inline id *autoreleaseFast(id obj)
    {
        AutoreleasePoolPage *page = hotPage();
        if (page && !page->full()) { //有 hotPage 并且当前 page 不满，则添加到该页的栈上
            return page->add(obj);
        } else if (page) {//有 hotPage 并且当前页已满，则新建一页，然后添加到该页的栈上
            return autoreleaseFullPage(obj, page);
        } else {//没有 hotPage 则新建一页，添加到该页的栈上
            return autoreleaseNoPage(obj);
        }
    }
    
// pop 核心操作
static inline void pop(void *token) {
    //找到对应的page
    AutoreleasePoolPage *page = pageForPointer(token);
    id *stop = (id *)token;
    
    //释放当前栈的对象，直到 stop
    //会调用对象的 relasese 方法
    page->releaseUntil(stop);

    //把子页干掉，其实就是把链表后面的全干掉
    if (page->child) {
        if (page->lessThanHalfFull()) {
            page->child->kill();
        } else if (page->child->child) {
            page->child->child->kill();
        }
    }
}    
```

* 当对象调用 autorelease 方法时，会将对象加入 AutoreleasePoolPage 的栈中
* 调用 AutoreleasePoolPage::pop 方法会向栈中的对象发送 release 消息


#### 为啥 App 启动后 AutoreleasePool 就生效了呢？

App启动后，苹果在主线程RunLoop 里注册了两个 Observer，

第一个 Observer 监视的事件是 Entry(即将进入Loop），其回调会调用objc_autoreleasePoolPush() 创建自动释放池。优先级最高；

第二个 Observer 监视了两个事件： BeforeWaiting(准备进入休眠）时调用 objc_autoreleasePoolPop() 和 objc_autoreleasePoolPush() 释放旧的池并创建新池。Exit(即将退出Loop) 时调用 objc_autoreleasePoolPop() 来释放自动释放池。


### 子线程AutoRelease对象何时释放

在子线程中，默认是不开启runloop的，那么使用 autoRelease 对象会内存泄漏吗，什么时候会释放？

由以上源码可知, 调用 autoRelease 方法后，在autoreleaseNoPage 方法中，会创建一个hotPage，然后调用page->add(obj)。也就是说即使这个线程没有AutorelesepoolPage，使用了autorelease对象时也会new一个AutoreleasepoolPage出来管理autorelese对象，不用担心内存泄漏。

那么什么时候会释放呢？

经过实践打断点，如果子线程没有开启runloop的话，可以看到子线程退出时 `_pthread_exit`会调用`tls_dealloc` 方法清除自动释放池：

```
static void tls_dealloc(void *p) 
{
   if (p == (void*)EMPTY_POOL_PLACEHOLDER) {
       // No objects or pool pages to clean up here.
       return;
   }

   // reinstate TLS value while we work
   setHotPage((AutoreleasePoolPage *)p);

   if (AutoreleasePoolPage *page = coldPage()) {
       if (!page->empty()) pop(page->begin());  // pop all of the pools
       if (DebugMissingPools || DebugPoolAllocation) {
           // pop() killed the pages already
       } else {
           page->kill();  // free all of the pages
       }
   }
   
   // clear TLS value so TLS destruction doesn't loop
   setHotPage(nil);
}
```

所以：

* 子线程在使用autorelease对象时，如果没有AutoreleasePool会在autoreleaseNoPage中懒加载一个出来。
* 在runloop的run:beforeDate，以及一些source的callback中，有 AutoreleasePool 的push和pop操作
* 在线程exit的时候会释放资源，执行AutoreleasePoolPage::tls_dealloc，在这里面会清空AutoreleasePool。

### 什么情况会将对象放到自动释放池

编译器编译时会为以下对象添加 autorelease 方法:

* 对象作为方法返回值
* 通过类方法创建对象
* 使用如下便捷语法：

```
NSArray *array = @[@"xxx"];
NSNumber *number = @1234;
```


### 参考

* [黑幕背后的Autorelease](http://blog.sunnyxx.com/2014/10/15/behind-autorelease/)
* [自动释放池的前世今生](https://github.com/draveness/analyze/blob/master/contents/objc/%E8%87%AA%E5%8A%A8%E9%87%8A%E6%94%BE%E6%B1%A0%E7%9A%84%E5%89%8D%E4%B8%96%E4%BB%8A%E7%94%9F.md)
* [子线程AutoRelease对象何时释放](https://suhou.github.io/2018/01/21/%E5%B8%A6%E7%9D%80%E9%97%AE%E9%A2%98%E7%9C%8B%E6%BA%90%E7%A0%81----%E5%AD%90%E7%BA%BF%E7%A8%8BAutoRelease%E5%AF%B9%E8%B1%A1%E4%BD%95%E6%97%B6%E9%87%8A%E6%94%BE/)


