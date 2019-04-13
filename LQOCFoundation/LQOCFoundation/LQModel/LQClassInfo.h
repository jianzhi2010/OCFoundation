//
//  LQClassInfo.h
//  LQOCFoundation
//
//  Created by liang on 2019/4/6.
//  Copyright © 2019 LQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

/**
 Type encoding's type.
 */
typedef NS_OPTIONS(NSUInteger, LQEncodingType) {
    LQEncodingTypeMask       = 0xFF, ///< mask of type value
    LQEncodingTypeUnknown    = 0, ///< unknown
    LQEncodingTypeVoid       = 1, ///< void
    LQEncodingTypeBool       = 2, ///< bool
    LQEncodingTypeInt8       = 3, ///< char / BOOL
    LQEncodingTypeUInt8      = 4, ///< unsigned char
    LQEncodingTypeInt16      = 5, ///< short
    LQEncodingTypeUInt16     = 6, ///< unsigned short
    LQEncodingTypeInt32      = 7, ///< int
    LQEncodingTypeUInt32     = 8, ///< unsigned int
    LQEncodingTypeInt64      = 9, ///< long long
    LQEncodingTypeUInt64     = 10, ///< unsigned long long
    LQEncodingTypeFloat      = 11, ///< float
    LQEncodingTypeDouble     = 12, ///< double
    LQEncodingTypeLongDouble = 13, ///< long double
    LQEncodingTypeObject     = 14, ///< id
    LQEncodingTypeClass      = 15, ///< Class
    LQEncodingTypeSEL        = 16, ///< SEL
    LQEncodingTypeBlock      = 17, ///< block
    LQEncodingTypePointer    = 18, ///< void*
    LQEncodingTypeStruct     = 19, ///< struct
    LQEncodingTypeUnion      = 20, ///< union
    LQEncodingTypeCString    = 21, ///< char*
    LQEncodingTypeCArray     = 22, ///< char[10] (for example)
    
    LQEncodingTypeQualifierMask   = 0xFF00,   ///< mask of qualifier
    LQEncodingTypeQualifierConst  = 1 << 8,  ///< const
    LQEncodingTypeQualifierIn     = 1 << 9,  ///< in
    LQEncodingTypeQualifierInout  = 1 << 10, ///< inout
    LQEncodingTypeQualifierOut    = 1 << 11, ///< out
    LQEncodingTypeQualifierBycopy = 1 << 12, ///< bycopy
    LQEncodingTypeQualifierByref  = 1 << 13, ///< byref
    LQEncodingTypeQualifierOneway = 1 << 14, ///< oneway
    
    LQEncodingTypePropertyMask         = 0xFF0000, ///< mask of property
    LQEncodingTypePropertyReadonly     = 1 << 16, ///< readonly
    LQEncodingTypePropertyCopy         = 1 << 17, ///< copy
    LQEncodingTypePropertyRetain       = 1 << 18, ///< retain
    LQEncodingTypePropertyNonatomic    = 1 << 19, ///< nonatomic
    LQEncodingTypePropertyWeak         = 1 << 20, ///< weak
    LQEncodingTypePropertyCustomGetter = 1 << 21, ///< getter=
    LQEncodingTypePropertyCustomSetter = 1 << 22, ///< setter=
    LQEncodingTypePropertyDynamic      = 1 << 23, ///< @dynamic
};

@interface LQClassIvarInfo : NSObject

@property (nonatomic, assign) Ivar ivar;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *typeEncoding;
@property (nonatomic, assign) LQEncodingType type;

- (instancetype)initWithIvar:(Ivar)ivar;

@end

@interface LQClassPropertyInfo : NSObject

@property (nonatomic, assign) objc_property_t property;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *typeEncoding;
@property (nonatomic, copy) NSString *ivarName;
@property (nonatomic, assign) LQEncodingType type;
@property (nonatomic, assign) Class cls;
@property (nonatomic, strong) NSArray<NSString *> *protocols;
@property (nonatomic, assign) SEL getter;
@property (nonatomic, assign) SEL setter;

- (instancetype)initWithProperty:(objc_property_t)property;

@end

@interface LQClassMethodInfo : NSObject

@property (nonatomic, assign) Method method;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *typeEncoding;
@property (nonatomic, copy) NSString *returnTypeEncoding;
@property (nonatomic, assign) LQEncodingType type;
@property (nonatomic, assign) SEL sel;
@property (nonatomic, assign) IMP imp;
@property (nonatomic, strong) NSArray<NSString *> *argumentTypeEncodings;

- (instancetype)initWithMethod:(Method)method;

@end

@interface LQClassInfo : NSObject

@property (nonatomic, assign) BOOL isMeta; ///< whether this class is meta class
@property (nonatomic, copy) NSString *name; ///< class name
@property (nonatomic, assign) Class cls;
@property (nonatomic, assign) Class metaCls;
@property (nonatomic, assign) Class superClass;
@property (nonatomic, strong) NSDictionary<NSString *, LQClassIvarInfo *> *ivarInfos;
@property (nonatomic, strong) NSDictionary<NSString *, LQClassPropertyInfo *> *propertyInfos;
@property (nonatomic, strong) NSDictionary<NSString *, LQClassMethodInfo *> *methodInfos;
@property (nonatomic, strong) LQClassInfo *superClassInfo;

+ (instancetype)classInfoWithClass:(Class)clazz;

@end

