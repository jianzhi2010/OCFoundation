# Runtime

OC 是动态语言，经过编译器阶段后并不能确定调用的函数，需要有一套运行时机制来动态地创建类和对象，进行消息传递和转发


## Runtime 应用

### Aspects


### 原理

其实就是 hook 对应方法，将原来的方法实现都替换为 `forwardInvocation:` 方法的实现，然后在 `forwardInvocation:` 方法中进行消息转发。

* 如果是 hook 实例对象的方法，会为该实例对象创建子类对象，并且修改它的isa指针和class方法（与KVO的实现类似），这样就能做到只影响该实例对象
* 如果是 hook 类对象的方法，那么只需要 hook 该类对象的方法即可，会影响所有的实例对象。


#### 使用注意

```
+ (id<AspectToken>)aspect_hookSelector:(SEL)selector
                           withOptions:(AspectOptions)options
                            usingBlock:(id)block
                                 error:(NSError **)error;

/// Adds a block of code before/instead/after the current `selector` for a specific instance.
- (id<AspectToken>)aspect_hookSelector:(SEL)selector
                           withOptions:(AspectOptions)options
                            usingBlock:(id)block
                                 error:(NSError **)error;
```

这两个接口看起来都很直观易用，需要注意的是，如果需要 hook 类方法，需要传入元类。


```
//传入元类，hook类方法
[object_getClass(NSObject.class) lq_hookSelector:@selector(debugDescription) options:LQAspectPositionBefore usingBlock:^(void) {
        NSLog(@"aspect-->");
} error:NULL];
```

因为在`forwardInvocation`在转发消息的时候，使用 `instancesRespondToSelector`判断类实例是否实现了该方法，而元类的实例就是类对象，实现了类方法。

```
Class klass = object_getClass(invocation.target);
do {
    if ((respondsToAlias = [klass instancesRespondToSelector:aliasSelector])) {
        [invocation invoke];
        break;
    }
} while (!respondsToAlias && (klass = class_getSuperclass(klass)));    
```


### 小知识点


* `class_getClassMethod` 与 `class_getInstanceMethod` 的区别在于： `class_getClassMethod` 会获取元类后调用 `class_getInstanceMethod` 

```

Method class_getClassMethod(Class cls, SEL sel)
{
    if (!cls  ||  !sel) return nil;

    return class_getInstanceMethod(cls->getMeta(), sel);
}

Method class_getInstanceMethod(Class cls, SEL sel)
{
    if (!cls  ||  !sel) return nil;

    // This deliberately avoids +initialize because it historically did so.

    // This implementation is a bit weird because it's the only place that 
    // wants a Method instead of an IMP.

#warning fixme build and search caches
        
    // Search method lists, try method resolver, etc.
    lookUpImpOrNil(cls, sel, nil, 
                   NO/*initialize*/, NO/*cache*/, YES/*resolver*/);

#warning fixme build and search caches

    return _class_getMethod(cls, sel);
}

```



##### 参考

* [面向切面编程之 Aspects 源码解析及应用](https://wereadteam.github.io/2016/06/30/Aspects/)
* [iOS 如何实现 Aspect Oriented Programming](https://halfrost.com/ios_aspect/)


