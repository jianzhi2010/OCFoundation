//
//  LQKeyValueObserveInfo.h
//  LQOCFoundation
//
//  Created by liang on 2019/4/15.
//  Copyright © 2019 LQ. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LQKeyValueObserveInfo : NSObject

@property (nonatomic, weak) id observer;
@property (nonatomic, assign) NSKeyValueObservingOptions options;
@property (nonatomic, copy) NSString *keyPath;

@end

NS_ASSUME_NONNULL_END
