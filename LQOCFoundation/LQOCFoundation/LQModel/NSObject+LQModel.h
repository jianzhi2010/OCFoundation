//
//  NSObject+LQModel.h
//  LQOCFoundation
//
//  Created by liang on 2019/4/6.
//  Copyright © 2019 LQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (LQModel)


+ (nullable instancetype)modelWithJSON:(id)json;


@end

NS_ASSUME_NONNULL_END
