//
//  LQAspects.m
//  LQOCFoundation
//
//  Created by liang on 2019/4/22.
//  Copyright © 2019 LQ. All rights reserved.
//

#import "LQAspects.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "LQTestUtil.h"
#import "LQAspectInfo.h"

static NSString *kLQSwizzlePrefix = @"LQAspects_";

@implementation NSObject (LQAspects)


+ (void)lq_hookSelector:(SEL)selector
                options:(LQAspectOptions)options
             usingBlock:(id)block
                  error:(NSError **)error {
    
    lq_aspectHook(self, selector, options, block, error);

}

- (void)lq_hookSelector:(SEL)selector
              options:(LQAspectOptions)options
           usingBlock:(id)block
                error:(NSError * _Nullable __autoreleasing *)error {
    lq_aspectHook(self, selector, options, block, error);
}

static void lq_aspectHook(id self, SEL selector, LQAspectOptions options, id block, NSError **error) {
    
    if (selector == nil || ![self respondsToSelector:selector] || block == nil) {
        return;
    }
    
    
    //1.swizzle class
    //2.swizzle selector
    //3.associate info
    
    Class swizzleClass = [self swizzleClassForwardInvocation];
//    [LQTestUtil printDescription:@"swizzle" object:self];
    
    
    [self swizzleWithClass:swizzleClass selector:selector];
//    [LQTestUtil printDescription:@"swizzle" object:self];
    
    
    LQAspectInfo *info = [LQAspectInfo infoWithSelector:selector object:self options:options block:block error:error];
    
    NSArray *infos = objc_getAssociatedObject(self, [self aliasForSelector:selector]);
    NSMutableArray *allInfos = [NSMutableArray array];
    if (infos.count > 0) {
        [allInfos addObjectsFromArray:infos];
    }
    [allInfos addObject:info];
    
    objc_setAssociatedObject(self, [self aliasForSelector:selector], allInfos, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}



- (void)swizzleWithClass:(Class)class selector:(SEL)selector {
    Method originalMethod = class_getInstanceMethod(class, selector);
    IMP originalImp = method_getImplementation(originalMethod);
    if (originalImp != _objc_msgForward) {
        
        SEL swizzleSel = [self aliasForSelector:selector];
        if (![class instancesRespondToSelector:swizzleSel]) {
            class_addMethod(class, swizzleSel, originalImp, method_getTypeEncoding(originalMethod));
        }
        
        class_replaceMethod(class, selector, _objc_msgForward, method_getTypeEncoding(originalMethod));
    }
}


- (SEL)aliasForSelector:(SEL)sel {
    return NSSelectorFromString([kLQSwizzlePrefix stringByAppendingFormat:@"_%@", NSStringFromSelector(sel)]);
}


- (Class)swizzleClassForwardInvocation {
    
    //1.swizzle isa
    //2.swizzle forwardInvocation
    //3.swizzle class
    
    Class clazz = self.class;
    NSString *currentClassName = NSStringFromClass(clazz);
    if ([currentClassName hasPrefix:kLQSwizzlePrefix]) {
        return clazz;
    } else if (class_isMetaClass(clazz)) {
        [self swizzleForwardInvocation:clazz];
        return clazz;
    }
    
    NSString *swizzleClassName = [NSString stringWithFormat:@"%@%@", kLQSwizzlePrefix, currentClassName];
    Class subClass = objc_getClass([swizzleClassName UTF8String]);
    if (!subClass) {
        subClass = objc_allocateClassPair(clazz, [swizzleClassName UTF8String], 0);
        if (!subClass) {
            return nil;
        }
        
        objc_registerClassPair(subClass);
        
        [self swizzleForwardInvocation:subClass];
        [self swizzleGetClass:subClass statedClass:clazz];
        [self swizzleGetClass:object_getClass(subClass) statedClass:clazz];
    }
   
    object_setClass(self, subClass);
    return subClass;
}

- (void)swizzleGetClass:(Class)clazz statedClass:(Class)statedClass {
    
    SEL sel = @selector(class);
    Method method = class_getInstanceMethod(clazz, sel);
    IMP swizzleImp = imp_implementationWithBlock(^(id self) {
        return statedClass;
    });
    
    class_replaceMethod(clazz, sel, swizzleImp, method_getTypeEncoding(method));
}

- (void)swizzleForwardInvocation:(Class)clazz {
    
    SEL originalSel = @selector(forwardInvocation:);
    SEL swizzleSel = @selector(lq_swizzleForwardInvocation:);
    
    Method originalMethod = class_getInstanceMethod(clazz, originalSel);
    Method swizzleMethod = class_getInstanceMethod(clazz, swizzleSel);

    IMP originalImp = method_getImplementation(originalMethod);
    IMP swizzleImp = method_getImplementation(swizzleMethod);

    const char * types = method_getTypeEncoding(class_getInstanceMethod([NSObject class], originalSel));
    
    
    if (class_addMethod(clazz, originalSel, swizzleImp, types)) {
        class_replaceMethod(clazz, swizzleSel, originalImp, types);
    } else {
        method_exchangeImplementations(originalMethod, swizzleMethod);
    }
    
}


- (void)lq_swizzleForwardInvocation:(NSInvocation *)invocation {
    
    //1.call before block
    //2.call original method
    //3.call after block
    
    SEL selector = invocation.selector;
    SEL swizzleSelector = [self aliasForSelector:selector];
    
    NSArray<LQAspectInfo *> *instanceInfos = objc_getAssociatedObject(self, [self aliasForSelector:selector]);
    NSArray<LQAspectInfo *> *classInfos = objc_getAssociatedObject(object_getClass(self), [self aliasForSelector:selector]);
    
    NSMutableArray *allInfos = [NSMutableArray array];
    if (instanceInfos.count > 0) {
        [allInfos addObjectsFromArray:instanceInfos];
    }
    if (classInfos.count > 0) {
        [allInfos addObjectsFromArray:classInfos];
    }
    
    [allInfos enumerateObjectsUsingBlock:^(LQAspectInfo * _Nonnull aspectInfo, NSUInteger idx, BOOL * _Nonnull stop) {
        if ((aspectInfo.options & LQAspectPositionBefore) == LQAspectPositionBefore) {
            //call block
            [aspectInfo invokeBlockWithOriginalInvocation:invocation];
        }
    }];
    
    //call original method
    invocation.selector = swizzleSelector;
    [invocation invoke];
    
    
    [allInfos enumerateObjectsUsingBlock:^(LQAspectInfo * _Nonnull aspectInfo, NSUInteger idx, BOOL * _Nonnull stop) {
        if ((aspectInfo.options & LQAspectPositionAfter) == LQAspectPositionAfter) {
            //call block
            [aspectInfo invokeBlockWithOriginalInvocation:invocation];
        }
    }];
}

@end
