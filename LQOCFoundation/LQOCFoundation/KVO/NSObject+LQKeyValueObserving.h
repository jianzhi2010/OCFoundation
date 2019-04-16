//
//  NSObject+LQKeyValueObserving.h
//  LQOCFoundation
//
//  Created by liang on 2019/4/13.
//  Copyright © 2019 LQ. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSObject (LQKeyValueObserving)

- (void)lq_addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context;

- (void)lq_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;

- (void)lq_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context;

@end

