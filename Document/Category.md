# Category


### Category 的结构

OC中的所有类和对象在runtime中都是用结构体表示的

```
struct category_t {
    const char *name;                           // 分类名
    classref_t cls;                             // 类
    struct method_list_t *instanceMethods;      //实例方法
    struct method_list_t *classMethods;         //类方法
    struct protocol_list_t *protocols;          //协议
    struct property_list_t *instanceProperties;
    // Fields below this point are not always present on disk.
    struct property_list_t *_classProperties;

    method_list_t *methodsForMeta(bool isMeta) {
        if (isMeta) return classMethods;
        else return instanceMethods;
    }

    property_list_t *propertiesForMeta(bool isMeta, struct header_info *hi);
};
```

比如以下分类代码

```
@interface NSObject (Addition)

@property (nonatomic, copy) NSString *func;

- (void)test;

@end

@implementation NSObject(Addition)

- (void)test {
    NSLog(@"--->%@", self.func);
}

@end
```

用 `clang rewrite-objc` 命令转换成C++代码，可以看到分类会转成 category_t 结构 ：

```
//代表一个分类
static struct _category_t _OBJC_$_CATEGORY_NSObject_$_Addition __attribute__ ((used, section ("__DATA,__objc_const"))) = 
{
	"NSObject",
	0, // &OBJC_CLASS_$_NSObject,
	(const struct _method_list_t *)&_OBJC_$_CATEGORY_INSTANCE_METHODS_NSObject_$_Addition,
	0,
	0,
	(const struct _prop_list_t *)&_OBJC_$_PROP_LIST_NSObject_$_Addition,
};

static struct /*_method_list_t*/ {
	unsigned int entsize;  // sizeof(struct _objc_method)
	unsigned int method_count;
	struct _objc_method method_list[1]; //一个方法
} _OBJC_$_CATEGORY_INSTANCE_METHODS_NSObject_$_Addition __attribute__ ((used, section ("__DATA,__objc_const"))) = {
	sizeof(_objc_method),
	1,
	//分类的方法
	{{(struct objc_selector *)"test", "v16@0:8", (void *)_I_NSObject_Addition_test}} 
};

static struct /*_prop_list_t*/ {
	unsigned int entsize;  // sizeof(struct _prop_t)
	unsigned int count_of_properties;
	struct _prop_t prop_list[1];  //一个属性
} _OBJC_$_PROP_LIST_NSObject_$_Addition __attribute__ ((used, section ("__DATA,__objc_const"))) = {
	sizeof(_prop_t),
	1,
	{{"func","T@\"NSString\",C,N"}} //分类中的属性
};
```

以上是编译阶段的成果，再来看runtime中是如何加载的：

### Category 的加载

```
void _objc_init(void)
{
    static bool initialized = false;
    if (initialized) return;
    initialized = true;
    
    // fixme defer initialization until an objc-using image is found?
    environ_init();
    tls_init();
    static_init();
    lock_init();
    exception_init();

    _dyld_objc_notify_register(&map_images, load_images, unmap_image);
}
```
首先在 OC runtime 的初始化中，会进行 `map_images`操作，然后会调用 `_read_images` 方法，在这方法最后面可以找到添加分类的逻辑：

```
// Discover categories. 
for (EACH_HEADER) {
   category_t **catlist = 
       _getObjc2CategoryList(hi, &count); //分类链表
   bool hasClassProperties = hi->info()->hasCategoryClassProperties();

   for (i = 0; i < count; i++) {
       category_t *cat = catlist[i];
       Class cls = remapClass(cat->cls);

       if (!cls) {
           // Category's target class is missing (probably weak-linked).
           // Disavow any knowledge of this category.
           catlist[i] = nil;
           if (PrintConnecting) {
               _objc_inform("CLASS: IGNORING category \?\?\?(%s) %p with "
                            "missing weak-linked target class", 
                            cat->name, cat);
           }
           continue;
       }

       // Process this category. 
       // First, register the category with its target class. 
       // Then, rebuild the class's method lists (etc) if 
       // the class is realized. 
       bool classExists = NO;
       if (cat->instanceMethods ||  cat->protocols  
           ||  cat->instanceProperties) 
       { // 添加实例方法、协议、属性
           addUnattachedCategoryForClass(cat, cls, hi);
           if (cls->isRealized()) {
               remethodizeClass(cls);
               classExists = YES;
           }
           if (PrintConnecting) {
               _objc_inform("CLASS: found category -%s(%s) %s", 
                            cls->nameForLogging(), cat->name, 
                            classExists ? "on existing class" : "");
           }
       }

       if (cat->classMethods  ||  cat->protocols  
           ||  (hasClassProperties && cat->_classProperties)) 
       { //添加类方法、协议
           addUnattachedCategoryForClass(cat, cls->ISA(), hi);
           if (cls->ISA()->isRealized()) {
               remethodizeClass(cls->ISA());
           }
           if (PrintConnecting) {
               _objc_inform("CLASS: found category +%s(%s)", 
                            cls->nameForLogging(), cat->name);
           }
       }
   }
}
```

从上面代码看到 1）把category的实例方法、协议以及属性添加到类上 2）把category的类方法和协议添加到类的metaclass上；
最终代码实现如下：

```
// Attach method lists and properties and protocols from categories to a class.
// Assumes the categories in cats are all loaded and sorted by load order, 
// oldest categories first.
static void 
attachCategories(Class cls, category_list *cats, bool flush_caches)
{
    if (!cats) return;
    if (PrintReplacedMethods) printReplacements(cls, cats);

    bool isMeta = cls->isMetaClass();

    // fixme rearrange to remove these intermediate allocations
    method_list_t **mlists = (method_list_t **)
        malloc(cats->count * sizeof(*mlists));
    property_list_t **proplists = (property_list_t **)
        malloc(cats->count * sizeof(*proplists));
    protocol_list_t **protolists = (protocol_list_t **)
        malloc(cats->count * sizeof(*protolists));

    // Count backwards through cats to get newest categories first
    int mcount = 0;
    int propcount = 0;
    int protocount = 0;
    int i = cats->count;
    bool fromBundle = NO;
    while (i--) {
        auto& entry = cats->list[i];

        method_list_t *mlist = entry.cat->methodsForMeta(isMeta);
        if (mlist) {
            mlists[mcount++] = mlist;
            fromBundle |= entry.hi->isBundle();
        }

        property_list_t *proplist = 
            entry.cat->propertiesForMeta(isMeta, entry.hi);
        if (proplist) {
            proplists[propcount++] = proplist;
        }

        protocol_list_t *protolist = entry.cat->protocols;
        if (protolist) {
            protolists[protocount++] = protolist;
        }
    }

    auto rw = cls->data();

    //添加实例方法到类的方法列表中
    prepareMethodLists(cls, mlists, mcount, NO, fromBundle);
    rw->methods.attachLists(mlists, mcount);
    free(mlists);
    if (flush_caches  &&  mcount > 0) flushCaches(cls);

    rw->properties.attachLists(proplists, propcount);
    free(proplists);

    rw->protocols.attachLists(protolists, protocount);
    free(protolists);
}
```

这里需要注意的是 `rw->methods.attachLists()` 这个方法，会把新增的分类方法插入到类的方法列表前面，所以说相同的分类方法会“覆盖”原来类的方法，因为查找方法的时候，是从类的方法列表从上到下查找，在列表前面找到之后就返回了。

```
void attachLists(List* const * addedLists, uint32_t addedCount) {
   if (addedCount == 0) return;

   if (hasArray()) {
       // many lists -> many lists
       uint32_t oldCount = array()->count;
       uint32_t newCount = oldCount + addedCount;
       setArray((array_t *)realloc(array(), array_t::byteSize(newCount)));
       array()->count = newCount;
       // 旧方法移动到后面
       memmove(array()->lists + addedCount, array()->lists, 
               oldCount * sizeof(array()->lists[0]));
       // 新的方法插入到数组前面
       memcpy(array()->lists, addedLists, 
              addedCount * sizeof(array()->lists[0]));
   }
   else if (!list  &&  addedCount == 1) {
       // 0 lists -> 1 list
       list = addedLists[0];
   } 
   else {
       // 1 list -> many lists
       List* oldList = list;
       uint32_t oldCount = oldList ? 1 : 0;
       uint32_t newCount = oldCount + addedCount;
       setArray((array_t *)malloc(array_t::byteSize(newCount)));
       array()->count = newCount;
       // 旧方法放在数组后面
       if (oldList) array()->lists[addedCount] = oldList;
       // 新的方法插入到数组前面
       memcpy(array()->lists, addedLists, 
              addedCount * sizeof(array()->lists[0]));
   }
}
```


### 问题

1. 在类的+load方法调用的时候，我们可以调用category中声明的方法么?
2. 类和分类都可以写 +load方法，那么调用顺序是怎样的呢？ 

关于第一个问题是可以，因为加载顺序先加载完分类，再调用 load 方法，

```
void _objc_init(void)
{ 
...
    // map_images 中加载了category， 在load_images中才去执行load方法
    _dyld_objc_notify_register(&map_images, load_images, unmap_image);
}
```

关于第二个问题: load的执行顺序是先类，后category，而category的+load执行顺序是根据编译顺序决定的。


### 参考

* [深入理解Objective-C：Category](https://tech.meituan.com/2015/03/03/diveintocategory.html)


