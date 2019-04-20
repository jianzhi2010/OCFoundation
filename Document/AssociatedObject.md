# Associated object

### 函数方法

```
// set
objc_setAssociatedObject(id _Nonnull object, const void * _Nonnull key,
                         id _Nullable value, objc_AssociationPolicy policy)

// get                          
objc_getAssociatedObject(id _Nonnull object, const void * _Nonnull key)
```

### 原理

使用一个全局的哈希表存储关联对象数据，被关联对象的内存地址作为key， value 又是一个map结构，存储了关联对象信息（包含关联对象和关联策略）

核心源码如下：

```

spinlock_t AssociationsManagerLock;

class AssociationsManager {
    // associative references: object pointer -> PtrPtrHashMap.
    static AssociationsHashMap *_map;
public:
    //创建时会上锁(其实是为了保证读取map是线程安全的)
    AssociationsManager()   { AssociationsManagerLock.lock(); }
    //销毁时解锁
    ~AssociationsManager()  { AssociationsManagerLock.unlock(); }
    
    AssociationsHashMap &associations() {
        if (_map == NULL)
            _map = new AssociationsHashMap();
        return *_map;
    }
};

AssociationsHashMap *AssociationsManager::_map = NULL;


// set
void _object_set_associative_reference(id object, void *key, id value, uintptr_t policy) {
    // retain the new value (if any) outside the lock.
    ObjcAssociation old_association(0, nil);
    id new_value = value ? acquireValue(value, policy) : nil;
    ( //这个花括号区域内，创建AssociationsManager时会上锁，释放AssociationsManager会解锁，保证了读取map是线程安全的
        AssociationsManager manager;
        AssociationsHashMap &associations(manager.associations());
        disguised_ptr_t disguised_object = DISGUISE(object);
        if (new_value) {
            // break any existing association.
            AssociationsHashMap::iterator i = associations.find(disguised_object);
            if (i != associations.end()) {
                // secondary table exists
                ObjectAssociationMap *refs = i->second;
                ObjectAssociationMap::iterator j = refs->find(key);
                if (j != refs->end()) {
                    old_association = j->second;
                    j->second = ObjcAssociation(policy, new_value);
                } else {
                    (*refs)[key] = ObjcAssociation(policy, new_value);
                }
            } else {
                // create the new association (first time).
                ObjectAssociationMap *refs = new ObjectAssociationMap;
                associations[disguised_object] = refs;
                (*refs)[key] = ObjcAssociation(policy, new_value);
                object->setHasAssociatedObjects();
            }
        } else {
            // setting the association to nil breaks the association.
            AssociationsHashMap::iterator i = associations.find(disguised_object);
            if (i !=  associations.end()) {
                ObjectAssociationMap *refs = i->second;
                ObjectAssociationMap::iterator j = refs->find(key);
                if (j != refs->end()) {
                    old_association = j->second;
                    refs->erase(j);
                }
            }
        }
    }
    // release the old value (outside of the lock).
    if (old_association.hasValue()) ReleaseValue()(old_association);
}

// get
id _object_get_associative_reference(id object, void *key) {
    id value = nil;
    uintptr_t policy = OBJC_ASSOCIATION_ASSIGN;
    {
        AssociationsManager manager;
        AssociationsHashMap &associations(manager.associations());
        //获取对象的内存地址
        disguised_ptr_t disguised_object = DISGUISE(object);
        //根据对象的内存地址，获取关联对象信息的map
        AssociationsHashMap::iterator i = associations.find(disguised_object); 
        if (i != associations.end()) {
            ObjectAssociationMap *refs = i->second;
            //根据key找到关联对象
            ObjectAssociationMap::iterator j = refs->find(key);
            if (j != refs->end()) {
                ObjcAssociation &entry = j->second;
                value = entry.value();
                policy = entry.policy();
                if (policy & OBJC_ASSOCIATION_GETTER_RETAIN) {
                    objc_retain(value);
                }
            }
        }
    }
    if (value && (policy & OBJC_ASSOCIATION_GETTER_AUTORELEASE)) {
        objc_autorelease(value);
    }
    return value;
}

```

### 注意点

* 关联对象的移除时机： 关联对象的移除时机和释放时机并不总是一致的
* 使用关联对象时，不要选择 `OBJC_ASSOCIATION_ASSIGN` 关联策略，容易crash，一般使用 `OBJC_ASSOCIATION_RETAIN_NONATOMIC` 即可 

### 参考

* [Objective-C Associated Objects 的实现原理](http://blog.leichunfeng.com/blog/2015/06/26/objective-c-associated-objects-implementation-principle/)
* [关联对象 AssociatedObject 完全解析](https://draveness.me/ao)

