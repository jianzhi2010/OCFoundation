//
//  LQModelMeta.m
//  LQOCFoundation
//
//  Created by liang on 2019/4/7.
//  Copyright © 2019 LQ. All rights reserved.
//

#import "LQModelMeta.h"
#import "LQModel.h"



/// Get the Foundation class type from property info.
static force_inline LQEncodingNSType LQClassGetNSType(Class cls) {
    if (!cls) return LQEncodingTypeNSUnknown;
    if ([cls isSubclassOfClass:[NSMutableString class]]) return LQEncodingTypeNSMutableString;
    if ([cls isSubclassOfClass:[NSString class]]) return LQEncodingTypeNSString;
    if ([cls isSubclassOfClass:[NSDecimalNumber class]]) return LQEncodingTypeNSDecimalNumber;
    if ([cls isSubclassOfClass:[NSNumber class]]) return LQEncodingTypeNSNumber;
    if ([cls isSubclassOfClass:[NSValue class]]) return LQEncodingTypeNSValue;
    if ([cls isSubclassOfClass:[NSMutableData class]]) return LQEncodingTypeNSMutableData;
    if ([cls isSubclassOfClass:[NSData class]]) return LQEncodingTypeNSData;
    if ([cls isSubclassOfClass:[NSDate class]]) return LQEncodingTypeNSDate;
    if ([cls isSubclassOfClass:[NSURL class]]) return LQEncodingTypeNSURL;
    if ([cls isSubclassOfClass:[NSMutableArray class]]) return LQEncodingTypeNSMutableArray;
    if ([cls isSubclassOfClass:[NSArray class]]) return LQEncodingTypeNSArray;
    if ([cls isSubclassOfClass:[NSMutableDictionary class]]) return LQEncodingTypeNSMutableDictionary;
    if ([cls isSubclassOfClass:[NSDictionary class]]) return LQEncodingTypeNSDictionary;
    if ([cls isSubclassOfClass:[NSMutableSet class]]) return LQEncodingTypeNSMutableSet;
    if ([cls isSubclassOfClass:[NSSet class]]) return LQEncodingTypeNSSet;
    return LQEncodingTypeNSUnknown;
}

/// Whether the type is c number.
static force_inline BOOL LQEncodingTypeIsCNumber(LQEncodingType type) {
    switch (type & LQEncodingTypeMask) {
        case LQEncodingTypeBool:
        case LQEncodingTypeInt8:
        case LQEncodingTypeUInt8:
        case LQEncodingTypeInt16:
        case LQEncodingTypeUInt16:
        case LQEncodingTypeInt32:
        case LQEncodingTypeUInt32:
        case LQEncodingTypeInt64:
        case LQEncodingTypeUInt64:
        case LQEncodingTypeFloat:
        case LQEncodingTypeDouble:
        case LQEncodingTypeLongDouble: return YES;
        default: return NO;
    }
}

@implementation LQModelPropertyMeta

+ (instancetype)metaWithClassInfo:(LQClassInfo *)classInfo propertyInfo:(LQClassPropertyInfo *)propertyInfo generic:(Class)generic {

    if (!classInfo || !propertyInfo) {
        return nil;
    }
    
    LQModelPropertyMeta *meta = [LQModelPropertyMeta new];
    meta.name = propertyInfo.name;
    meta.type = propertyInfo.type;
    meta.info = propertyInfo;
    meta.genericCls = generic;
    
    if ((meta.type & LQEncodingTypeMask) == LQEncodingTypeObject) {
        meta.nsType = LQClassGetNSType(propertyInfo.cls);
    } else {
        meta.isCNumber = LQEncodingTypeIsCNumber(meta.type);
    }
    if ((meta.type & LQEncodingTypeMask) == LQEncodingTypeStruct) {
        /*
         It seems that NSKeyedUnarchiver cannot decode NSValue except these structs:
         */
        static NSSet *types = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSMutableSet *set = [NSMutableSet new];
            // 32 bit
            [set addObject:@"{CGSize=ff}"];
            [set addObject:@"{CGPoint=ff}"];
            [set addObject:@"{CGRect={CGPoint=ff}{CGSize=ff}}"];
            [set addObject:@"{CGAffineTransform=ffffff}"];
            [set addObject:@"{UIEdgeInsets=ffff}"];
            [set addObject:@"{UIOffset=ff}"];
            // 64 bit
            [set addObject:@"{CGSize=dd}"];
            [set addObject:@"{CGPoint=dd}"];
            [set addObject:@"{CGRect={CGPoint=dd}{CGSize=dd}}"];
            [set addObject:@"{CGAffineTransform=dddddd}"];
            [set addObject:@"{UIEdgeInsets=dddd}"];
            [set addObject:@"{UIOffset=dd}"];
            types = set;
        });
        if ([types containsObject:propertyInfo.typeEncoding]) {
            meta->_isStructAvailableForKeyedArchiver = YES;
        }
    }
    meta.cls = propertyInfo.cls;
    
    if (generic) {
        meta.hasCustomClassFromDictionary = [generic respondsToSelector:@selector(modelCustomClassForDictionary:)];
    } else if (meta.cls && meta.nsType == LQEncodingTypeNSUnknown) {
        meta.hasCustomClassFromDictionary = [meta.cls respondsToSelector:@selector(modelCustomClassForDictionary:)];
    }
    if (propertyInfo.getter) {
        if ([classInfo.cls instancesRespondToSelector:propertyInfo.getter]) {
            meta.getter = propertyInfo.getter;
        }
    }
    if (propertyInfo.setter) {
        if ([classInfo.cls instancesRespondToSelector:propertyInfo.setter]) {
            meta.setter = propertyInfo.setter;
        }
    }
    
    if (meta->_getter && meta->_setter) {
        /*
         KVC invalid type:
         long double
         pointer (such as SEL/CoreFoundation object)
         */
        switch (meta.type & LQEncodingTypeMask) {
            case LQEncodingTypeBool:
            case LQEncodingTypeInt8:
            case LQEncodingTypeUInt8:
            case LQEncodingTypeInt16:
            case LQEncodingTypeUInt16:
            case LQEncodingTypeInt32:
            case LQEncodingTypeUInt32:
            case LQEncodingTypeInt64:
            case LQEncodingTypeUInt64:
            case LQEncodingTypeFloat:
            case LQEncodingTypeDouble:
            case LQEncodingTypeObject:
            case LQEncodingTypeClass:
            case LQEncodingTypeBlock:
            case LQEncodingTypeStruct:
            case LQEncodingTypeUnion: {
                meta->_isKVCCompatible = YES;
            } break;
            default: break;
        }
    }
    
    return meta;
}


@end


@implementation LQModelMeta

- (instancetype)initWithClass:(Class)clazz {
    if (!clazz) {
        return nil;
    }
    self = [super init];
    if (self) {
        _classInfo = [LQClassInfo classInfoWithClass:clazz];
        
        // Get container property's generic class
        NSMutableDictionary *genericMapper = [NSMutableDictionary new];
        if ([clazz respondsToSelector:@selector(modelContainerPropertyGenericClass)]) {
            NSDictionary *dict = [clazz modelContainerPropertyGenericClass];
            [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
                if (![key isKindOfClass:[NSString class]]) {
                    return ;
                }
                
                //if obj is Class object, object_getClass(obj) is metaClass
                Class meta = object_getClass(obj);
                if (!meta) {
                    return;
                }
                if (class_isMetaClass(meta)) {
                    [genericMapper setObject:obj forKey:key];
                } else if ([obj isKindOfClass:[NSString class]]) {
                    Class class = NSClassFromString(obj);
                    if (class) {
                        [genericMapper setObject:class forKey:key];
                    }
                }
            }];
            
        }
        
        // Create all property metas.
        __block LQClassInfo *currentClassInfo = _classInfo;
        NSMutableDictionary *allPropertyMetas = [NSMutableDictionary new];
        while (currentClassInfo && currentClassInfo.superClass) {
            
            for (LQClassPropertyInfo *propertyInfo in currentClassInfo.propertyInfos.allValues) {
                LQModelPropertyMeta *meta = [LQModelPropertyMeta metaWithClassInfo:_classInfo propertyInfo:propertyInfo generic:genericMapper[propertyInfo.name]];
                [allPropertyMetas setObject:meta forKey:meta.name];
            }
            
            currentClassInfo = [currentClassInfo superClassInfo];
        }
        _allPropertyMetas = [allPropertyMetas.allValues copy];
        
        // create mapper
        NSMutableDictionary *mapper = [NSMutableDictionary new];
        NSMutableArray *keyPathPropertyMetas = [NSMutableArray new];

        if ([clazz respondsToSelector:@selector(modelCustomPropertyMapper)]) {
            NSDictionary *customMapper = [clazz modelCustomPropertyMapper];
            [customMapper enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull propertyName, NSString *  _Nonnull mappedToKey, BOOL * _Nonnull stop) {
                LQModelPropertyMeta *propertyMeta = allPropertyMetas[propertyName];
                if (!propertyMeta) {
                    return ;
                }
                [allPropertyMetas removeObjectForKey:propertyName];
                
                if ([mappedToKey isKindOfClass:[NSString class]]) {
                    if (mappedToKey.length ==0) {
                        return;
                    }
                    propertyMeta.mappedToKey = mappedToKey;
                    
                    NSArray *keyPath = [mappedToKey componentsSeparatedByString:@"."];
                    if (keyPath.count > 1) {
                        propertyMeta.mappedToKeyPath = keyPath;
                        [keyPathPropertyMetas addObject:propertyMeta];
                    }
                    mapper[mappedToKey] = propertyMeta;
                }
                
            }];
        }
        [allPropertyMetas enumerateKeysAndObjectsUsingBlock:^(NSString *name, LQModelPropertyMeta *propertyMeta, BOOL *stop) {
            mapper[name] = propertyMeta;
        }];
        _mapper = mapper;
        _keyPathPropertyMetas = keyPathPropertyMetas;

        _hasCustomClassFromDictionary = [clazz respondsToSelector:@selector(modelCustomClassForDictionary:)];
        _hasCustomTransformFromDictionary = [clazz respondsToSelector:@selector(modelCustomTransformFromDictionary:)];
        
    }
    return self;
}

@end
