//
//  LQClassInfo.m
//  LQOCFoundation
//
//  Created by liang on 2019/4/6.
//  Copyright © 2019 LQ. All rights reserved.
//

#import "LQClassInfo.h"

LQEncodingType LQEncodingGetType(const char *typeEncoding) {
    char *type = (char *)typeEncoding;
    if (!type) {
        return LQEncodingTypeUnknown;
    }
    size_t len = strlen(type);
    if (len == 0) {
        return LQEncodingTypeUnknown;
    }
    
    LQEncodingType qualifier = 0;
    bool prefix = true;
    while (prefix) {
        switch (*type) {
            case 'r': {
                qualifier |= LQEncodingTypeQualifierConst;
                type++;
            } break;
            case 'n': {
                qualifier |= LQEncodingTypeQualifierIn;
                type++;
            } break;
            case 'N': {
                qualifier |= LQEncodingTypeQualifierInout;
                type++;
            } break;
            case 'o': {
                qualifier |= LQEncodingTypeQualifierOut;
                type++;
            } break;
            case 'O': {
                qualifier |= LQEncodingTypeQualifierBycopy;
                type++;
            } break;
            case 'R': {
                qualifier |= LQEncodingTypeQualifierByref;
                type++;
            } break;
            case 'V': {
                qualifier |= LQEncodingTypeQualifierOneway;
                type++;
            } break;
            default: {
                prefix = false;
            } break;
        }
    }
    
    len = strlen(type);
    if (len == 0) {
        return LQEncodingTypeUnknown | qualifier;
    }
    
    switch (*type) {
        case 'v': return LQEncodingTypeVoid | qualifier;
        case 'B': return LQEncodingTypeBool | qualifier;
        case 'c': return LQEncodingTypeInt8 | qualifier;
        case 'C': return LQEncodingTypeUInt8 | qualifier;
        case 's': return LQEncodingTypeInt16 | qualifier;
        case 'S': return LQEncodingTypeUInt16 | qualifier;
        case 'i': return LQEncodingTypeInt32 | qualifier;
        case 'I': return LQEncodingTypeUInt32 | qualifier;
        case 'l': return LQEncodingTypeInt32 | qualifier;
        case 'L': return LQEncodingTypeUInt32 | qualifier;
        case 'q': return LQEncodingTypeInt64 | qualifier;
        case 'Q': return LQEncodingTypeUInt64 | qualifier;
        case 'f': return LQEncodingTypeFloat | qualifier;
        case 'd': return LQEncodingTypeDouble | qualifier;
        case 'D': return LQEncodingTypeLongDouble | qualifier;
        case '#': return LQEncodingTypeClass | qualifier;
        case ':': return LQEncodingTypeSEL | qualifier;
        case '*': return LQEncodingTypeCString | qualifier;
        case '^': return LQEncodingTypePointer | qualifier;
        case '[': return LQEncodingTypeCArray | qualifier;
        case '(': return LQEncodingTypeUnion | qualifier;
        case '{': return LQEncodingTypeStruct | qualifier;
        case '@': {
            if (len == 2 && *(type + 1) == '?')
                return LQEncodingTypeBlock | qualifier;
            else
                return LQEncodingTypeObject | qualifier;
        }
        default: return LQEncodingTypeUnknown | qualifier;
    }
}

@implementation LQClassIvarInfo

- (instancetype)initWithIvar:(Ivar)ivar {
    if (!ivar) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        _ivar = ivar;
        
        const char *name = ivar_getName(ivar);
        _name = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
        
        const char *typeEncoding = ivar_getTypeEncoding(ivar);
        if (typeEncoding) {
            _typeEncoding = [NSString stringWithCString:typeEncoding encoding:NSUTF8StringEncoding];
            _type = LQEncodingGetType(typeEncoding);
        }
    }
    return self;
}

@end

@implementation LQClassPropertyInfo

- (instancetype)initWithProperty:(objc_property_t)property {
    if (!property) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        _property = property;
        
        const char *name = property_getName(property);
        _name = [NSString stringWithCString:name encoding:NSUTF8StringEncoding];
        
        LQEncodingType type = 0;
        unsigned int count;
        objc_property_attribute_t *attrs = property_copyAttributeList(property, &count);
        for (unsigned int i=0; i<count; i++) {
            switch (attrs[i].name[0]) {
                case 'T': { // Type encoding
                    if (attrs[i].value) {
                        _typeEncoding = [NSString stringWithUTF8String:attrs[i].value];
                        type = LQEncodingGetType(attrs[i].value);

                        if ((type & LQEncodingTypeMask) == LQEncodingTypeObject && _typeEncoding.length) {
                            NSScanner *scanner = [NSScanner scannerWithString:_typeEncoding];
                            if (![scanner scanString:@"@\"" intoString:NULL]) continue;

                            NSString *clsName = nil;
                            if ([scanner scanUpToCharactersFromSet: [NSCharacterSet characterSetWithCharactersInString:@"\"<"] intoString:&clsName]) {
                                if (clsName.length) _cls = objc_getClass(clsName.UTF8String);
                            }

                            NSMutableArray *protocols = nil;
                            while ([scanner scanString:@"<" intoString:NULL]) {
                                NSString* protocol = nil;
                                if ([scanner scanUpToString:@">" intoString: &protocol]) {
                                    if (protocol.length) {
                                        if (!protocols) protocols = [NSMutableArray new];
                                        [protocols addObject:protocol];
                                    }
                                }
                                [scanner scanString:@">" intoString:NULL];
                            }
                            _protocols = protocols;
                        }
                    }
                } break;
                case 'V': { // Instance variable
                    if (attrs[i].value) {
                        _ivarName = [NSString stringWithUTF8String:attrs[i].value];
                    }
                } break;
                case 'R': {
                    type |= LQEncodingTypePropertyReadonly;
                } break;
                case 'C': {
                    type |= LQEncodingTypePropertyCopy;
                } break;
                case '&': {
                    type |= LQEncodingTypePropertyRetain;
                } break;
                case 'N': {
                    type |= LQEncodingTypePropertyNonatomic;
                } break;
                case 'D': {
                    type |= LQEncodingTypePropertyDynamic;
                } break;
                case 'W': {
                    type |= LQEncodingTypePropertyWeak;
                } break;
                case 'G': {
                    type |= LQEncodingTypePropertyCustomGetter;
                    if (attrs[i].value) {
                        _getter = NSSelectorFromString([NSString stringWithUTF8String:attrs[i].value]);
                    }
                } break;
                case 'S': {
                    type |= LQEncodingTypePropertyCustomSetter;
                    if (attrs[i].value) {
                        _setter = NSSelectorFromString([NSString stringWithUTF8String:attrs[i].value]);
                    }
                } // break; commented for code coverage in next line
                default: break;
            }
        }
        if (attrs) {
            free(attrs);
            attrs = NULL;
        }
        _type = type;

    }
    
    return self;
}

@end

@implementation LQClassMethodInfo

- (instancetype)initWithMethod:(Method)method {
    if (!method) {
        return nil;
    }
    
    self = [super init];
    if (self) {
        _method = method;
        _sel = method_getName(method);
        _name = NSStringFromSelector(_sel);
        _imp = method_getImplementation(method);
        
        const char *typeEncoding = method_getTypeEncoding(method);
        if (typeEncoding) {
            _typeEncoding = [NSString stringWithCString:typeEncoding encoding:NSUTF8StringEncoding];
            _type = LQEncodingGetType(typeEncoding);
        }
        
        char *returnTypeEncoding = method_copyReturnType(method);
        if (returnTypeEncoding) {
            _returnTypeEncoding = [NSString stringWithCString:returnTypeEncoding encoding:NSUTF8StringEncoding];
            free(returnTypeEncoding);
        }
        
        unsigned int count = method_getNumberOfArguments(method);
        NSMutableArray *argumentTypes = [NSMutableArray arrayWithCapacity:count];
        for (int i=0; i<count; i++) {
            char *argumentType = method_copyArgumentType(method, i);
            NSString *type = [NSString stringWithCString:argumentType encoding:NSUTF8StringEncoding];
            [argumentTypes addObject:type];
            free(argumentType);
        }
        _argumentTypeEncodings = argumentTypes;
    }
    return self;
}


@end


@implementation LQClassInfo

- (instancetype)initWithClass:(Class)clazz {
    self = [super init];
    if (self) {
        _cls = clazz;
        _superClass = class_getSuperclass(clazz);
        [self update];
        
        _superClassInfo = [self.class classInfoWithClass:_superClass];
    }
    return self;
}

- (void)update {
    
    unsigned int count;
    Ivar *ivarList = class_copyIvarList(_cls, &count);
    NSMutableDictionary *ivarInfos = [NSMutableDictionary dictionaryWithCapacity:count];
    for (unsigned int i=0; i<count; i++) {
        Ivar ivar = ivarList[i];
        LQClassIvarInfo *ivarInfo = [[LQClassIvarInfo alloc] initWithIvar:ivar];
        [ivarInfos setObject:ivarInfo forKey:ivarInfo.name];
    }
    _ivarInfos = ivarInfos;
    free(ivarList);
    
    objc_property_t *propertyList = class_copyPropertyList(_cls, &count);
    NSMutableDictionary *propertyInfos = [NSMutableDictionary dictionaryWithCapacity:count];
    for (unsigned int i=0; i<count; i++) {
        objc_property_t property = propertyList[i];
        LQClassPropertyInfo *proertyInfo = [[LQClassPropertyInfo alloc] initWithProperty:property];
        [propertyInfos setObject:proertyInfo forKey:proertyInfo.name];
    }
    _propertyInfos = propertyInfos;
    free(propertyList);
    
    Method *methodList =class_copyMethodList(_cls, &count);
    NSMutableDictionary *methodInfos = [NSMutableDictionary dictionaryWithCapacity:count];
    for (unsigned int i=0; i<count; i++) {
        Method method = methodList[i];
        LQClassMethodInfo *methodInfo = [[LQClassMethodInfo alloc] initWithMethod:method];
        [methodInfos setObject:methodInfo forKey:methodInfo.name];
    }
    _methodInfos = methodInfos;
    free(methodList);
    
}


+ (instancetype)classInfoWithClass:(Class)clazz {
    if (!clazz) {
        return nil;
    }
    
    static NSMutableDictionary *classCache;
    static NSMutableDictionary *metaCache;
    static dispatch_semaphore_t lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        classCache = [NSMutableDictionary dictionary];
        metaCache = [NSMutableDictionary dictionary];
        lock = dispatch_semaphore_create(1);
    });
    
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    LQClassInfo *info = class_isMetaClass(clazz) ? [metaCache objectForKey:NSStringFromClass(clazz)] : [classCache objectForKey:NSStringFromClass(clazz)];
    dispatch_semaphore_signal(lock);
    
    if (!info) {
        // maybe run this code multiple times , no big problem
        info = [[LQClassInfo alloc] initWithClass:clazz];
        if (info) {
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
                if (class_isMetaClass(clazz)) {
                    [metaCache setObject:info forKey:NSStringFromClass(clazz)];
                } else {
                    [classCache setObject:info forKey:NSStringFromClass(clazz)];
                }
            dispatch_semaphore_signal(lock);
        }
    }
    
    return info;
}

@end
