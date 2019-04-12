//
//  LQModelMeta.h
//  LQOCFoundation
//
//  Created by liang on 2019/4/7.
//  Copyright © 2019 LQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQClassInfo.h"

#define force_inline __inline__ __attribute__((always_inline))

/// Foundation Class Type
typedef NS_ENUM (NSUInteger, LQEncodingNSType) {
    LQEncodingTypeNSUnknown = 0,
    LQEncodingTypeNSString,
    LQEncodingTypeNSMutableString,
    LQEncodingTypeNSValue,
    LQEncodingTypeNSNumber,
    LQEncodingTypeNSDecimalNumber,
    LQEncodingTypeNSData,
    LQEncodingTypeNSMutableData,
    LQEncodingTypeNSDate,
    LQEncodingTypeNSURL,
    LQEncodingTypeNSArray,
    LQEncodingTypeNSMutableArray,
    LQEncodingTypeNSDictionary,
    LQEncodingTypeNSMutableDictionary,
    LQEncodingTypeNSSet,
    LQEncodingTypeNSMutableSet,
};


@interface LQModelPropertyMeta : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) LQEncodingType type;
@property (nonatomic, assign) LQEncodingNSType nsType;

@property (nonatomic, assign) Class cls;
@property (nonatomic, assign) Class genericCls;
@property (nonatomic, assign) SEL getter;
@property (nonatomic, assign) SEL setter;

@property (nonatomic, copy) NSString *mappedToKey;
@property (nonatomic, copy) NSArray *mappedToKeyPath;

@property (nonatomic, strong) LQClassPropertyInfo *info;
@property (nonatomic, assign) BOOL isCNumber;
@property (nonatomic, assign) BOOL isKVCCompatible;
@property (nonatomic, assign) BOOL hasCustomClassFromDictionary;
@property (nonatomic, assign) BOOL isStructAvailableForKeyedArchiver;


+ (instancetype)metaWithClassInfo:(LQClassInfo *)classInfo propertyInfo:(LQClassPropertyInfo *)propertyInfo generic:(Class)generic;

@end


@interface LQModelMeta : NSObject

@property (nonatomic, strong) LQClassInfo *classInfo;
@property (nonatomic, strong) NSArray<LQModelPropertyMeta *> *allPropertyMetas;
@property (nonatomic, strong) NSArray<LQModelPropertyMeta *> *keyPathPropertyMetas;

@property (nonatomic, strong) NSDictionary *mapper;

@property (nonatomic, assign) BOOL hasCustomTransformFromDictionary;
@property (nonatomic, assign) BOOL hasCustomClassFromDictionary;


- (instancetype)initWithClass:(Class)clazz;

@end

