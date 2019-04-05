//
//  LQNotification.h
//  LQOCFoundation
//
//  Created by liang on 2019/4/1.
//  Copyright © 2019 LQ. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface LQNotification : NSObject

@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSDictionary *userInfo;
@property (nonatomic, strong, readonly) id object;

- (instancetype)initWithName:(NSNotificationName)name object:(nullable id)object userInfo:(nullable NSDictionary *)userInfo;

@end
