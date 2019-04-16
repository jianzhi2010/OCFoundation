//
//  NSObject+LQKeyValueObserving.m
//  LQOCFoundation
//
//  Created by liang on 2019/4/13.
//  Copyright © 2019 LQ. All rights reserved.
//

#import "NSObject+LQKeyValueObserving.h"
#import "objc/runtime.h"
#import "objc/message.h"
#import "LQKeyValueObserveInfo.h"

const void *kLQKvoKey = &kLQKvoKey;

@implementation NSObject (LQKeyValueObserving)


void lq_kvo_setter_short(id self, SEL cmd, short newValue) {
    lq_kvo_setter_object(self, cmd, @(newValue));
}
void lq_kvo_setter_unsigned_short(id self, SEL cmd, unsigned short newValue) {
    lq_kvo_setter_object(self, cmd, @(newValue));
}
void lq_kvo_setter_int(id self, SEL cmd, int newValue) {
    lq_kvo_setter_object(self, cmd, @(newValue));
}
void lq_kvo_setter_unsigned_int(id self, SEL cmd, unsigned int newValue) {
    lq_kvo_setter_object(self, cmd, @(newValue));
}
void lq_kvo_setter_long(id self, SEL cmd, long newValue) {
    lq_kvo_setter_object(self, cmd, @(newValue));
}
void lq_kvo_setter_long_long(id self, SEL cmd, long long newValue) {
    lq_kvo_setter_object(self, cmd, @(newValue));
}
void lq_kvo_setter_unsigned_long(id self, SEL cmd, unsigned long newValue) {
    lq_kvo_setter_object(self, cmd, @(newValue));
}
void lq_kvo_setter_bool(id self, SEL cmd, BOOL newValue) {
    lq_kvo_setter_object(self, cmd, @(newValue));
}
void lq_kvo_setter_float(id self, SEL cmd, float newValue) {
    lq_kvo_setter_object(self, cmd, @(newValue));
}
void lq_kvo_setter_double(id self, SEL cmd, double newValue) {
    lq_kvo_setter_object(self, cmd, @(newValue));
}
void lq_kvo_setter_char(id self, SEL cmd, char newValue) {
    lq_kvo_setter_object(self, cmd, @(newValue));
}
void lq_kvo_setter_object(id self, SEL cmd, id newValue) {
    
    //1.调用父类的setter方法设置新值
    //2.通知观察者
    
    // set new value
    Class selfClass = object_getClass(self);
    Method method = class_getInstanceMethod(selfClass, cmd);
    const char *typeEncoding = method_getTypeEncoding(method);
    Class supperClass = class_getSuperclass(selfClass);
    IMP supperImp = class_getMethodImplementation(supperClass, cmd);
    
    lq_kvo_set_value(self, cmd, supperImp, newValue, typeEncoding);
    
    // notify
    NSArray<LQKeyValueObserveInfo *> *allInfos = objc_getAssociatedObject(self, kLQKvoKey);
    if (!allInfos) {
        return;
    }
    
    NSMutableArray<LQKeyValueObserveInfo *> *notifyInfos = [NSMutableArray arrayWithCapacity:allInfos.count];
    NSString *getterName = lq_kvo_getterSELName(cmd);
    [allInfos enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(LQKeyValueObserveInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.keyPath isEqualToString:getterName]) {
            [notifyInfos addObject:obj];
        }
    }];
    
    for (LQKeyValueObserveInfo *info in notifyInfos) {
        NSMutableDictionary *dict = [NSMutableDictionary new];
        if ((info.options & NSKeyValueObservingOptionOld) == NSKeyValueObservingOptionOld) {
            SEL getterSEL = NSSelectorFromString(getterName);
            Method getterMethod = class_getInstanceMethod(supperClass, getterSEL);
            const char *getterTypeEncoding = method_getTypeEncoding(getterMethod);
            dict[NSKeyValueChangeOldKey] = lq_kvo_get_value(self, getterTypeEncoding, getterSEL) ?: [NSNull null];
        }
        if ((info.options & NSKeyValueObservingOptionNew) == NSKeyValueObservingOptionNew) {
            dict[NSKeyValueChangeNewKey] = newValue ?: [NSNull null];
        }
        
        if ([info.observer respondsToSelector:@selector(lq_observeValueForKeyPath:ofObject:change:context:)]) {
            [info.observer lq_observeValueForKeyPath:info.keyPath ofObject:self change:dict context:NULL];
        }
    }
}

NSString *lq_kvo_getterSELName(SEL setterSEL) {
    // eg. setFunction
    NSString *methodName = [NSString stringWithFormat:@"%s", sel_getName(setterSEL)];
    methodName = [methodName substringToIndex:methodName.length-1]; //remove last char ':'
    NSString *firstString = [methodName substringWithRange:NSMakeRange(3, 1)];
    // eg. function
    methodName = [NSString stringWithFormat:@"%@%@", [firstString lowercaseString], [methodName substringFromIndex:4]];
    return methodName;
}

void lq_kvo_set_value(id receiver, SEL cmd, IMP imp, id newValue, const char * typeEncoding) {
    NSString *type = [[NSString stringWithUTF8String:typeEncoding] substringFromIndex:@"v24@0:8".length];
    if ([type containsString:[NSString stringWithUTF8String:@encode(char)]]) {
        char c = [newValue charValue];
        ((void(*)(id,SEL,char))(void *)imp)(receiver, cmd, c);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(short)]]) {
        short s = [newValue shortValue];
        ((void(*)(id,SEL,short))(void *)imp)(receiver, cmd, s);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(int)]]) {
        ((void(*)(id,SEL,int))(void *)imp)(receiver, cmd, [newValue intValue]);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(long)]]) {
        ((void(*)(id,SEL,long))(void *)imp)(receiver, cmd, [newValue longValue]);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(long long)]]) {
        ((void(*)(id,SEL,long long))(void *)imp)(receiver, cmd, [newValue longLongValue]);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned char)]]) {
        ((void(*)(id,SEL,unsigned char))(void *)imp)(receiver, cmd, [newValue unsignedCharValue]);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned short)]]) {
        ((void(*)(id,SEL,unsigned short))(void *)imp)(receiver, cmd, [newValue unsignedShortValue]);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned int)]]) {
        ((void(*)(id,SEL,unsigned int))(void *)imp)(receiver, cmd, [newValue unsignedIntValue]);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned long)]]) {
        ((void(*)(id,SEL,unsigned long))(void *)imp)(receiver, cmd, [newValue unsignedLongValue]);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned long long)]]) {
        ((void(*)(id,SEL,unsigned long long))(void *)imp)(receiver, cmd, [newValue unsignedLongLongValue]);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(BOOL)]]) {
        ((void(*)(id,SEL,BOOL))(void *)imp)(receiver, cmd, [newValue boolValue]);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(float)]]) {
        ((void(*)(id,SEL,float))(void *)imp)(receiver, cmd, [newValue floatValue]);
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(double)]]) {
        ((void(*)(id,SEL,double))(void *)imp)(receiver, cmd, [newValue doubleValue]);
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(id)]]) {
        ((void(*)(id,SEL,id))(void *)imp)(receiver, cmd, newValue);
    } else {
        NSLog(@"set value error...");
    }
}

id lq_kvo_get_value(NSObject* self, const char *typeEncoding, SEL getAttrSEL) {
    NSString *type = [[NSString stringWithUTF8String:typeEncoding] substringFromIndex:@"v24@0:8".length];
    if ([type containsString:[NSString stringWithUTF8String:@encode(char)]]) {
        char oldValue = ((char(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL);
        return [NSString stringWithFormat:@"%c", oldValue];
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(short)]]) {
        return @(((short(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(int)]]) {
        return @(((int(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(long)]]) {
        return @(((long(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(long long)]]) {
        return @(((long long(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned char)]]) {
        char oldValue = ((unsigned char (*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL);
        return [NSString stringWithFormat:@"%c", oldValue];
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned short)]]) {
        return @(((unsigned short(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned int)]]) {
        return @(((unsigned int(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned long)]]) {
        return @(((unsigned long(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned long long)]]) {
        return @(((unsigned long long(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(bool)]]) {
        return @(((bool (*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(float)]]) {
        return @(((float (*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
        
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(double)]]) {
        return @(((double(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL));
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(id)]]) {
        return ((id(*)(id,SEL))(void *)objc_msgSend)(self, getAttrSEL);
    }
    return nil;
}

IMP lq_kvo_IMPWithTypeEncoding(const char *typeEncoding) {
    NSString *type = [[NSString stringWithUTF8String:typeEncoding] substringFromIndex:@"v24@0:8".length];
    if ([type containsString:[NSString stringWithUTF8String:@encode(char)]]) {
        return (IMP)lq_kvo_setter_char;
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(short)]]) {
        return (IMP)lq_kvo_setter_short;
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(int)]]) {
        return (IMP)lq_kvo_setter_int;
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(long)]]) {
        return (IMP)lq_kvo_setter_long;
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(long long)]]) {
        return (IMP)lq_kvo_setter_long_long;
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned short)]]) {
        return (IMP)lq_kvo_setter_unsigned_short;
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned int)]]) {
        return (IMP)lq_kvo_setter_unsigned_int;
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(unsigned long)]]) {
        return (IMP)lq_kvo_setter_unsigned_long;
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(bool)]]) {
        return (IMP)lq_kvo_setter_bool;
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(float)]]) {
        return (IMP)lq_kvo_setter_float;
    } else if ([type containsString:[NSString stringWithUTF8String:@encode(double)]]) {
        return (IMP)lq_kvo_setter_double;
    } else {
        return (IMP)lq_kvo_setter_object;
    }
}

- (Class)getKVOClass {
    Class class = self.class;
    if ([NSStringFromClass(class) hasPrefix:@"LQKVO_"]) {
        return class;
    }
    
    NSString *kvoClassName = [NSString stringWithFormat:@"LQKVO_%@", NSStringFromClass(class)];
    Class kvoClass = objc_getClass([kvoClassName UTF8String]);
    if (!kvoClass) {
        kvoClass = objc_allocateClassPair(class, [kvoClassName UTF8String], 0);
        if (!kvoClass) {
            return nil;
        }
        objc_registerClassPair(kvoClass);
    }
    
    return kvoClass;
}

- (void)addSetMethodForKeyPath:(NSString *)keyPath {
    if (!keyPath.length) {
        return;
    }
    
    Class class = self.class;
    
    NSString *setter = [NSString stringWithFormat:@"set%@%@:", [[keyPath substringToIndex:1] uppercaseString], [[keyPath substringFromIndex:1] lowercaseString]];
    SEL setterSEL = NSSelectorFromString(setter);
    const char *typeEncoding = method_getTypeEncoding(class_getInstanceMethod(class, setterSEL));
    IMP setterIMP = lq_kvo_IMPWithTypeEncoding(typeEncoding);
    BOOL result = class_addMethod(class, setterSEL, setterIMP, typeEncoding);
    if (!result) {
        NSLog(@"already add method:%@", setter);
    }
}

- (void)lq_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context {
    if (!observer || !keyPath.length) {
        return;
    }
    
    //1.生成kvo子类
    //2.swizzle 原来的isa指针
    //3.子类添加setter方法，覆盖父类的setter方法
    //4.子类覆写 class 方法，返回父类的class
    //5.添加关联对象，记录监听者
    //todo : support keyPath + 4.
    
    // swizzle isa
    Class kvoClass = [self getKVOClass];
    if (!kvoClass) {
        return;
    }
    object_setClass(self, kvoClass);
    [self addSetMethodForKeyPath:keyPath];
    
    // add observe info
    LQKeyValueObserveInfo *info = [[LQKeyValueObserveInfo alloc] init];
    info.observer = observer;
    info.keyPath = keyPath;
    info.options = options;

    NSArray *infos = objc_getAssociatedObject(self, kLQKvoKey);
    NSMutableArray *newInfos = nil;
    if (infos) {
        newInfos = [NSMutableArray arrayWithArray:infos];
    } else {
        newInfos = [NSMutableArray array];
    }
    [newInfos addObject:info];
    objc_setAssociatedObject(self, kLQKvoKey, newInfos, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
}

- (void)lq_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    if (!observer || keyPath.length == 0) {
        return;
    }
    NSArray *infos = objc_getAssociatedObject(self, kLQKvoKey);
    if (!infos.count) {
        return;
    }
    
    NSMutableArray<LQKeyValueObserveInfo *> *toRemoveInfos = [NSMutableArray arrayWithArray:infos];
    
    [toRemoveInfos enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(LQKeyValueObserveInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.observer == observer && [keyPath isEqualToString:obj.keyPath]) {
            [toRemoveInfos removeObject:obj];
        }
    }];
    
    if (toRemoveInfos.count != infos.count) {
        objc_setAssociatedObject(self, kLQKvoKey, toRemoveInfos, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    if (toRemoveInfos.count == 0) {
        Class originClass = class_getSuperclass(self.class);
        object_setClass(self, originClass);
    }

}

- (void)lq_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"%@ call: %@", self, NSStringFromSelector(_cmd));
    
}

@end


