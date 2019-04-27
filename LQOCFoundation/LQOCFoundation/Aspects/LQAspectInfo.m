//
//  LQAspectInfo.m
//  LQOCFoundation
//
//  Created by liang on 2019/4/27.
//  Copyright © 2019 LQ. All rights reserved.
//

#import "LQAspectInfo.h"

// Block internals.
typedef NS_OPTIONS(int, AspectBlockFlags) {
    AspectBlockFlagsHasCopyDisposeHelpers = (1 << 25),
    AspectBlockFlagsHasSignature          = (1 << 30)
};
typedef struct _AspectBlock {
    __unused Class isa;
    AspectBlockFlags flags;
    __unused int reserved;
    void (__unused *invoke)(struct _AspectBlock *block, ...);
    struct {
        unsigned long int reserved;
        unsigned long int size;
        // requires AspectBlockFlagsHasCopyDisposeHelpers
        void (*copy)(void *dst, const void *src);
        void (*dispose)(const void *);
        // requires AspectBlockFlagsHasSignature
        const char *signature;
        const char *layout;
    } *descriptor;
    // imported variables
} *AspectBlockRef;

static NSMethodSignature *aspect_blockMethodSignature(id block, NSError **error) {
    AspectBlockRef layout = (__bridge void *)block;
    if (!(layout->flags & AspectBlockFlagsHasSignature)) {
        NSString *description = [NSString stringWithFormat:@"The block %@ doesn't contain a type signature.", block];
        return nil;
    }
    void *desc = layout->descriptor;
    desc += 2 * sizeof(unsigned long int);
    if (layout->flags & AspectBlockFlagsHasCopyDisposeHelpers) {
        desc += 2 * sizeof(void *);
    }
    if (!desc) {
        NSString *description = [NSString stringWithFormat:@"The block %@ doesn't has a type signature.", block];
        return nil;
    }
    const char *signature = (*(const char **)desc);
    return [NSMethodSignature signatureWithObjCTypes:signature];
}

@implementation LQAspectInfo

+ (instancetype)infoWithSelector:(SEL)selector object:(id)object options:(LQAspectOptions)options block:(id)block error:(NSError **)error {

    if (selector == nil || block == nil) {
        return nil;
    }
    
    LQAspectInfo *info = [LQAspectInfo new];
    info.options = options;
    info.selector = selector;
    info.block = block;
    info.blockSignature = aspect_blockMethodSignature(block, error);
    
    return info;
}


- (void)invokeBlockWithOriginalInvocation:(NSInvocation *)invocation {
    if (self.blockSignature.numberOfArguments > invocation.methodSignature.numberOfArguments) {
        return;
    }
    
    //invocation methodSignature 的第一个参数是receiver, 第二个参数是selector
    //block methodSignature 的第一个参数是receiver, 第二个参数没有selector

    NSInvocation *blockInvocation = [NSInvocation invocationWithMethodSignature:self.blockSignature];
    
    if (self.blockSignature.numberOfArguments > 1) {
        [blockInvocation setArgument:(void *)self atIndex:1];
    }
    
    void *argBuf = NULL;
    for (int i=2; i<self.blockSignature.numberOfArguments; i++) {
        const char* type = [invocation.methodSignature getArgumentTypeAtIndex:i];
        NSUInteger argSize;
        NSGetSizeAndAlignment(type, &argSize, NULL);
        if (!(argBuf = reallocf(argBuf, argSize))) {
            return;
        }
        
        [invocation getArgument:argBuf atIndex:i];
        [blockInvocation setArgument:argBuf atIndex:i];
    }
    [blockInvocation invokeWithTarget:self.block];

    if (argBuf != NULL) {
        free(argBuf);
    }
    
}

@end
