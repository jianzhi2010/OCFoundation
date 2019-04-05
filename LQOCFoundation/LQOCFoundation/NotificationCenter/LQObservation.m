//
//  LQObservation.m
//  LQOCFoundation
//
//  Created by liang on 2019/3/27.
//  Copyright © 2019 LQ. All rights reserved.
//

#import "LQObservation.h"
#import <objc/runtime.h>


@interface LQDeallocProxy : NSObject


@end

@interface LQDeallocProxy()

@property (nonatomic, copy) void (^deallocCallback)(LQDeallocProxy *proxy);

@end

@implementation LQDeallocProxy


- (instancetype)initWithDeallcCallback:(void (^)(LQDeallocProxy *proxy))deallocCallback {
    self = [super init];
    if (self) {
        _deallocCallback = deallocCallback;
    }
    return self;
}

- (void)dealloc {
    if (_deallocCallback) {
        _deallocCallback(self);
    }
}

@end

@interface LQObservation()

@property (nonatomic, copy) void (^observerDeallocCallback)(LQObservation *notification);

@end

@implementation LQObservation

- (void)addObserverDeallocCallback:(void (^)(LQObservation *))callback {
    _observerDeallocCallback = callback;
    
    if (_observer && callback) {
        __weak __typeof(self) weakSelf = self;
        LQDeallocProxy *proxy = [[LQDeallocProxy alloc] initWithDeallcCallback:^(LQDeallocProxy *proxy) {
            if (weakSelf.observerDeallocCallback) {
                weakSelf.observerDeallocCallback(self);
            }
        }];
        objc_setAssociatedObject(_observer, @selector(setObserver:) , proxy, OBJC_ASSOCIATION_RETAIN);
    }
}

@end

