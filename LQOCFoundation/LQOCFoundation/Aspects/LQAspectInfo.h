//
//  LQAspectInfo.h
//  LQOCFoundation
//
//  Created by liang on 2019/4/27.
//  Copyright © 2019 LQ. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, LQAspectOptions) {
    LQAspectPositionAfter   = 1,            /// Called after the original implementation (default)
    LQAspectPositionInstead = 1<<1,         /// Will replace the original implementation.
    LQAspectPositionBefore  = 1<<2,        /// Called before the original implementation.
    
    LQAspectOptionAutomaticRemoval = 1 << 3, /// Will remove the hook after the first execution.
};

NS_ASSUME_NONNULL_BEGIN

@interface LQAspectInfo : NSObject

@property (nonatomic, assign) SEL selector;
@property (nonatomic, assign) LQAspectOptions options;
@property (nonatomic, copy) id block;
@property (nonatomic, strong) NSMethodSignature *blockSignature;
@property (nonatomic, weak) id object;

+ (instancetype)infoWithSelector:(SEL)selector object:(id)object options:(LQAspectOptions)options block:(id)block error:(NSError **)error;

- (void)invokeBlockWithOriginalInvocation:(NSInvocation *)invocation;

@end

NS_ASSUME_NONNULL_END
