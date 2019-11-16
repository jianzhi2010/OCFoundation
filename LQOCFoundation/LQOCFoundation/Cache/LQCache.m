//
//  LQCache.m
//  LQOCFoundation
//
//  Created by liang on 2019/5/25.
//  Copyright © 2019 LQ. All rights reserved.
//

#import "LQCache.h"
#import "LQMemoryCache.h"

@interface LQCache()

@property (nonatomic, strong) LQMemoryCache *memoryCache;

@end

@implementation LQCache

- (instancetype)init {
    self = [super init];
    if (self) {
        _memoryCache = [[LQMemoryCache alloc] init];
    }
    return self;
}

- (id)objectForKey:(NSString *)key {
    
    return nil;
}

- (void)objectForKey:(NSString *)key complection:(void(^)(id obj))completion {

}

- (BOOL)setObject:(id)obj forKey:(NSString *)key {
    
    return YES;
}

- (void)setObject:(id)obj forKey:(NSString *)key complection:(void(^)(BOOL success))completion {
    
}

@end
