//
//  LQObservation.h
//  LQOCFoundation
//
//  Created by liang on 2019/3/27.
//  Copyright © 2019 LQ. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LQNotification;

@interface LQObservation : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) id object;
@property (nonatomic, weak) id observer;
@property (nonatomic, assign) SEL selector;

- (void)addObserverDeallocCallback:(void (^)(LQObservation *observation))callback;

@end
