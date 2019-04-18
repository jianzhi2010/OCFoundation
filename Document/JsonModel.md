# JsonModel

- 内联函数?

建议编译器将指定的函数体插入并取代每一处调用该函数的地方（上下文），从而节省了每次调用函数带来的额外时间开支。

> 与宏的比较：宏调用并不执行类型检查，甚至连正常参数也不检查，但是函数调用却要检查。


- `instancesRespondToSelector` vs `respondToSelector`

`instancesRespondToSelector` : 类方法，用于判断该类的实例是否实现某实例方法；
`respondToSelector` ：既是类方法、也是实例方法，类调用此方法用于判断类方法是否存在，实例调用的话用于判断某实例方法是否存在


- `objc_msgSend` : 给对象发送消息

需要注意使用时的传值类型，如果不对应则参数无效

```
// property
@property (nonatomic, assign) float count;
@property (nonatomic, copy) NSString *name;

//-----
[self performSelector:@selector(setName:) withObject:@"hh"];
NSLog(@"name--->%@", self.name); //print: hh

[self performSelector:@selector(setCount:) withObject:@33.5];
NSLog(@"count--->%.1f", self.count); //print: 0.0

((void (*)(id, SEL, double))(void *) objc_msgSend)((id)self, @selector(setCount:), 33.5);
NSLog(@"count----->%.1f", self.count); //print: 0.0

((void (*)(id, SEL, float))(void *) objc_msgSend)((id)self, @selector(setCount:), 33.5);
NSLog(@"count----->%.1f", self.count); //print: 33.5
```

`performSelector` 的实现也是通过 objc_msgSend

```
+ (id)performSelector:(SEL)sel withObject:(id)obj {
if (!sel) [self doesNotRecognizeSelector:sel];
return ((id(*)(id, SEL, id))objc_msgSend)((id)self, sel, obj);
}
```

### 参考

* [YYModel 分析](https://blog.ibireme.com/2015/10/23/ios_model_framework_benchmark/)

