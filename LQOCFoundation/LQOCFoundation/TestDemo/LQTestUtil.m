//
//  LQTestUtil.m
//  LQOCFoundation
//
//  Created by liang on 2019/4/16.
//  Copyright © 2019 LQ. All rights reserved.
//

#import "LQTestUtil.h"
#import <objc/runtime.h>

@implementation LQTestUtil


+ (NSArray *)classMethodNames:(Class)cls {
    NSMutableArray *array = [NSMutableArray array];
    unsigned int methodCount = 0;
    Method *methodList = class_copyMethodList(cls, &methodCount);
    unsigned int i;
    for (i = 0; i < methodCount; i++) {
        [array addObject:NSStringFromSelector(method_getName(methodList[i]))];
    }
    
    free(methodList);
    
    return array;
}

+ (void)printDescription:(NSString *)name object:(id)obj {
    struct objc_object *objcet = (__bridge struct objc_object *)obj;
    
    Class cls = objcet->isa;
    
    NSString *str = [NSString stringWithFormat:@"%@: %@\n\tNSObject class %s\n\tlibobjc class %s : super class %s\n\timplements methods <%@>",
                     name,
                     obj,
                     class_getName([obj class]),
                     class_getName(cls),
                     class_getName(class_getSuperclass(cls)),
                     [[self classMethodNames:cls] componentsJoinedByString:@", "]
                     ];
    printf("%s\n", [str UTF8String]);
}

@end
