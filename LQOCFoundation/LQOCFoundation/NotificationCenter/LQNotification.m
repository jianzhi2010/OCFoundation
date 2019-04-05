//
//  LQNotification.m
//  LQOCFoundation
//
//  Created by liang on 2019/4/1.
//  Copyright © 2019 LQ. All rights reserved.
//

#import "LQNotification.h"

@interface LQNotification()

@property (nonatomic, copy, readwrite) NSString *name;
@property (nonatomic, copy, readwrite) NSDictionary *userInfo;
@property (nonatomic, strong, readwrite) id object;

@end


@implementation LQNotification


- (instancetype)initWithName:(NSNotificationName)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo {
    self = [super init];
    if (self) {
        _name = name;
        _object = object;
        _userInfo = userInfo;
    }
    return self;
}


@end
