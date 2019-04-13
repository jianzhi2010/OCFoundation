//
//  NSObject+LQModel.m
//  LQOCFoundation
//
//  Created by liang on 2019/4/6.
//  Copyright © 2019 LQ. All rights reserved.
//

#import "NSObject+LQModel.h"
#import <objc/message.h>
#import "LQClassInfo.h"
#import "LQModelMeta.h"


@implementation NSObject (LQModel)


+ (nullable instancetype)modelWithJSON:(id)json {
    if (!json) {
        return nil;
    }
    NSDictionary *dict = [self dictionaryWithJSON:json];
    if (!dict) {
        return nil;
    }
    
    id object = [[self.class alloc] init];
    if ([object modelSetWithDictionary:dict]) {
        return object;
    }
    
    return nil;
}

- (BOOL)modelSetWithDictionary:(NSDictionary *)dict {
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return NO;
    }
    
    LQModelMeta *meta = [[LQModelMeta alloc] initWithClass:self.class];
    if (!meta) {
        return NO;
    }
    
    [dict enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        LQModelPropertyMeta *propertyMeta = [meta.mapper objectForKey:key];
        if (!propertyMeta) {
            return ;
        }
        
        [self setupWithPropertyMeta:propertyMeta originValue:obj];
    }];
    
    //keypath
    for (LQModelPropertyMeta *property in meta.keyPathPropertyMetas) {
        __block id value = dict;
        [property.mappedToKeyPath enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if ([value isKindOfClass:[NSDictionary class]] && value[obj]) {
                value = value[obj];
            } else {
                value = nil;
                *stop = YES;
            }
        }];
        
        if (value) {
            [self setupWithPropertyMeta:property originValue:value];
        }
    }
    
    return YES;
}

- (void)setupWithPropertyMeta:(LQModelPropertyMeta *)propertyMeta originValue:(id)value {
    if (!value || !propertyMeta) {
        return ;
    }
    
    id finalValue = nil;
    switch (propertyMeta.nsType) {
        case LQEncodingTypeNSArray:
        case LQEncodingTypeNSMutableArray:
        {
            if (propertyMeta.genericCls) {
                NSMutableArray *array = [NSMutableArray array];
                NSArray *values = [value isKindOfClass:[NSArray class]] ? value : nil;
                for (id one in values) {
                    id generic = [propertyMeta.genericCls modelWithJSON:one];
                    if (generic) {
                        [array addObject:generic];
                    }
                }
                if (array.count > 0) {
                    finalValue = array.copy;
                }
            } else {
                finalValue = value;
            }
        }
            break;
        default:
        {
            if (propertyMeta.genericCls) {
                id generic = [propertyMeta.genericCls modelWithJSON:value];
                if (generic) {
                    finalValue = generic;
                }
            } else {
                finalValue = value;
            }
        }
            break;
    }
    
    if (!finalValue) {
        return ;
    }
    
    if (!propertyMeta.isCNumber && propertyMeta.setter) {
        ((void (*)(id, SEL, id))(void *) objc_msgSend)((id)self, propertyMeta.setter, finalValue);
    } else {
        [self setValue:finalValue forKey:propertyMeta.name];
    }
}

+ (NSDictionary *)dictionaryWithJSON:(id)json {
    if (json == nil) {
        return nil;
    }
    
    NSDictionary *dict = json;
    
    NSData *jsonData = nil;
    if ([json isKindOfClass:[NSString class]]) {
        jsonData = [json dataUsingEncoding:NSUTF8StringEncoding];
    } else if ([json isKindOfClass:[NSData class]]) {
        jsonData = json;
    }
    if (jsonData) {
        dict = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:NULL];
    }
    
    if (![dict isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    return dict;
}

@end
