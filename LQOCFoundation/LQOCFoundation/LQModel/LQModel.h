//
//  LQModel.h
//  LQOCFoundation
//
//  Created by liang on 2019/4/7.
//  Copyright © 2019 LQ. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LQModel <NSObject>

@optional
+ (NSDictionary<NSString *, id> *)modelCustomPropertyMapper;

+ (nullable NSDictionary<NSString *, id> *)modelContainerPropertyGenericClass;

+ (nullable Class)modelCustomClassForDictionary:(NSDictionary *)dictionary;

+ (BOOL)modelCustomTransformFromDictionary:(NSDictionary *)dictionary;


@end
