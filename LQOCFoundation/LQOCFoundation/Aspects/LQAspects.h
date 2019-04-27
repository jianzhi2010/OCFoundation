//
//  LQAspects.h
//  LQOCFoundation
//
//  Created by liang on 2019/4/22.
//  Copyright © 2019 LQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQAspectInfo.h"


NS_ASSUME_NONNULL_BEGIN

@interface NSObject (LQAspects)


+ (void)lq_hookSelector:(SEL)selector
                options:(LQAspectOptions)options
             usingBlock:(id)block
                  error:(NSError **)error;

/// Adds a block of code before/instead/after the current `selector` for a specific instance.
- (void)lq_hookSelector:(SEL)selector
                options:(LQAspectOptions)options
             usingBlock:(id)block
                  error:(NSError **)error;

@end

NS_ASSUME_NONNULL_END
