//
//  LQTestModel.m
//  LQOCFoundation
//
//  Created by liang on 2019/4/14.
//  Copyright © 2019 LQ. All rights reserved.
//

#import "LQTestModel.h"


@implementation LQModelParent

+ (void)initialize {
    //如果子类没有实现initialize的话，父类的initialize会被调用多次
    NSLog(@"initialize--->parent %@", self);
    if (self == [LQModelParent class]) {
        NSLog(@"initialize--->check %@", self);
    }
}

- (void)setManualNotifyObject:(NSString *)manualNotifyObject {
    // you have to call willChangeValueForKey & didChangeValueForKey
    [self willChangeValueForKey:@"manualNotifyObject"];
    _manualNotifyObject = manualNotifyObject;
    [self didChangeValueForKey:@"manualNotifyObject"];
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key {
    if ([key isEqualToString:@"manualNotifyObject"]) {
        return NO;
    }
    return [super automaticallyNotifiesObserversForKey:key];
}

@end


@implementation LQModelToy

- (void)runWithSpeed:(double)speed {
    NSLog(@"runWithSpeed:%.2f", speed);
}

- (void)dealloc {
    NSLog(@"dealloc:%@", self);
}

@end


@implementation LQModelChild

+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper {
    return @{
             @"nickName" : @"nick",
             @"status" : @"ext.s",
             };
}

+ (nullable NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass {
    return @{
             @"father" : @"LQModelParent",
             @"mother" : LQModelParent.class,
             @"toys" : LQModelToy.class,
             };
}

@end
