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


@interface LQObserver : NSObject

@property (nonatomic, strong) NSOperationQueue *queue;
@property (nonatomic, copy) void (^notificationCallback)(LQNotification *note);

- (void)didReceiveNotification:(LQNotification *)note;

@end


@implementation LQObserver


- (void)didReceiveNotification:(LQNotification *)note {
    if (self.queue) {
        __weak __typeof(self) weakSelf = self;
        [self.queue addOperationWithBlock:^{
            if (weakSelf.notificationCallback) {
                weakSelf.notificationCallback(note);
            }
        }];
    } else {
        self.notificationCallback(note);
    }
}

@end

@interface LQNotificationCenter()


@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray<LQObservation *> *> *observations;
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
    
    LQObserver *observer = [[LQObserver alloc] init];
    observer.queue = queue;
    observer.notificationCallback = block;
    [self addObserver:observer selector:@selector(didReceiveNotification:) name:name object:obj];
    
    return observer;
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
        [weakSelf removeObserver:observation.observer name:observation.name object:observation.object];
    }];
    
    [self.lock lock];
    
    NSMutableArray *list = [self.observations objectForKey:aName];
    if (list) {
        [list addObject:observation];
    } else {
        list = [NSMutableArray array];
        [list addObject:observation];
        [self.observations setObject:list forKey:aName];
    }
    
    [self.lock unlock];
}


- (void)postNotificationName:(NSString *)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo {
    if (!name.length) {
        return;
    }
    
    [self.lock lock];
    NSMutableArray<LQObservation *> *list = [self.observations objectForKey:name];
    if (!list) {
        [self.lock unlock];
        return;
    }
    
    __block NSMutableArray<LQObservation *> *observations = [NSMutableArray array];
    [list enumerateObjectsUsingBlock:^(LQObservation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!obj.object || obj.object == object) {
            [observations addObject:obj];
        }
    }];
    
    [self.lock unlock];

    LQNotification *notification = [[LQNotification alloc] initWithName:name object:object userInfo:userInfo];
    [observations enumerateObjectsUsingBlock:^(LQObservation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.observer performSelector:obj.selector withObject:notification];
    }];
}

- (void)removeObserver:(id)observer {
    [self removeObserver:observer name:nil object:nil];
}

- (void)removeObserver:(id)observer name:(nullable NSNotificationName)aName object:(nullable id)anObject {

    [self.lock lock];

    if (aName.length) {
        NSMutableArray<LQObservation *> *list = [self.observations objectForKey:aName];
        [list enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(LQObservation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.name && [obj.name isEqualToString:aName]) {
                [list removeObject:obj];
            }
        }];
    } else {
        [self.observations enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<LQObservation *> * _Nonnull list, BOOL * _Nonnull stop) {
            
            [list enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(LQObservation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.observer && obj.observer == observer) {
                    [list removeObject:obj];
                }
            }];
        }];
    }
    
    [self.lock unlock];
}

@end
