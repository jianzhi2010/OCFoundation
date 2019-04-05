//
//  LQNotificationCenter.m
//  LQOCFoundation
//
//  Created by liang on 2019/3/26.
//  Copyright © 2019 LQ. All rights reserved.
//

#import "LQNotificationCenter.h"
#import "LQNotification.h"
#import "LQObservation.h"


@interface LQNotificationCenter()


@property (nonatomic, strong) NSMutableDictionary<NSString *, LQObservation *> *observations;
@property (nonatomic, strong) dispatch_queue_t observationQueue;
@property (nonatomic, strong) NSRecursiveLock *lock;

@end


@implementation LQNotificationCenter


+ (instancetype)defaultCenter {
    static id center;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        center = [[self alloc] init];
    });
    return center;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _observations = [NSMutableDictionary dictionary];
        _lock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

- (id <NSObject>)addObserverForName:(nullable NSNotificationName)name object:(nullable id)obj queue:(nullable NSOperationQueue *)queue usingBlock:(void (^)(LQNotification *note))block {
    if (!block) {
        return nil;
    }
    
    LQObservation *observation = [[LQObservation alloc] init];
    observation.object = obj;
    observation.name = name;
    observation.queue = queue;
    observation.notificationCallback = block;
    __weak __typeof(self) weakSelf = self;
    [observation addObserverDeallocCallback:^(LQObservation *observation) {
        [weakSelf.lock lock];
        [weakSelf.observations removeObjectForKey:observation.name];
        [weakSelf.lock unlock];
    }];
    
    [self.lock lock];
    [self.observations setObject:observation forKey:name];
    [self.lock unlock];
    
    return observation;
}

- (void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSString *)aName object:(nullable id)anObject {
    if (!observer || !aSelector || ![observer respondsToSelector:aSelector]) {
        return;
    }
    
    LQObservation *observation = [[LQObservation alloc] init];
    observation.observer = observer;
    observation.object = anObject;
    observation.name = aName;
    observation.selector = aSelector;
    __weak __typeof(self) weakSelf = self;
    [observation addObserverDeallocCallback:^(LQObservation *observation) {
        [weakSelf.lock lock];
        [weakSelf.observations removeObjectForKey:observation.name];
        [weakSelf.lock unlock];
    }];
    
    [self.lock lock];
    [self.observations setObject:observation forKey:aName];
    [self.lock unlock];
}

- (void)postNotificationName:(NSString *)name object:(nullable id)anObject {
    if (!name.length) {
        return;
    }
    
    [self.lock lock];
    LQObservation *observation = [self.observations objectForKey:name];
    [self.lock unlock];
    
    if (!observation) {
        return;
    }
    
    if (observation.object && anObject != observation.object) {
        return ;
    }
    
    if (observation.selector) {
        LQNotification *notification = [[LQNotification alloc] initWithName:name object:anObject userInfo:nil];
        [observation.observer performSelector:observation.selector withObject:notification];
    }
    
    if (observation.notificationCallback) {
        LQNotification *notification = [[LQNotification alloc] initWithName:name object:anObject userInfo:nil];
        if (observation.queue) {
            [observation.queue addOperationWithBlock:^{
                observation.notificationCallback(notification);
            }];
        } else {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                observation.notificationCallback(notification);
            }];
        }
    }
    
}

- (void)removeObserver:(id)observer {
    [self removeObserver:observer name:nil object:nil];
}

- (void)removeObserver:(id)observer name:(nullable NSNotificationName)aName object:(nullable id)anObject {

    [self.lock lock];

    if (aName.length) {
        LQObservation *observation = [self.observations objectForKey:aName];
        if (observation.observer && observation.observer == observer) {
            [self.observations removeObjectForKey:aName];
        }
    } else {
        [self.observations enumerateKeysAndObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSString * _Nonnull key, LQObservation * _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj.observer && obj.observer == observer) {
                [self.observations removeObjectForKey:obj.name];
            }
        }];
    }
    
    [self.lock unlock];
}

@end
