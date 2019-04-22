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


### 参考

* [黑幕背后的Autorelease](http://blog.sunnyxx.com/2014/10/15/behind-autorelease/)
* [自动释放池的前世今生](https://github.com/draveness/analyze/blob/master/contents/objc/%E8%87%AA%E5%8A%A8%E9%87%8A%E6%94%BE%E6%B1%A0%E7%9A%84%E5%89%8D%E4%B8%96%E4%BB%8A%E7%94%9F.md)


