//
//  LQNotificationCenter.h
//  LQOCFoundation
//
//  Created by liang on 2019/3/26.
//  Copyright © 2019 LQ. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class LQNotification;

@interface LQNotificationCenter : NSObject

+ (instancetype)defaultCenter;

- (void)postNotificationName:(NSString *)name object:(nullable id)anObject;

- (void)addObserver:(id)observer selector:(SEL)aSelector name:(nullable NSNotificationName)aName object:(nullable id)anObject;

- (id <NSObject>)addObserverForName:(nullable NSNotificationName)name object:(nullable id)obj queue:(nullable NSOperationQueue *)queue usingBlock:(void (^)(LQNotification *note))block;

- (void)removeObserver:(id)observer name:(nullable NSString *)aName object:(nullable id)anObject;

@end

NS_ASSUME_NONNULL_END
