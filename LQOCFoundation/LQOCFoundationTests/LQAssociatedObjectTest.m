//
//  LQAssociatedObjectTest.m
//  LQOCFoundationTests
//
//  Created by liang on 2019/4/20.
//  Copyright © 2019 LQ. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LQTestModel.h"
#import <objc/runtime.h>
#import "LQUnitTestUtil.h"

@interface LQAssociatedObjectTest : XCTestCase

@end

@implementation LQAssociatedObjectTest

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testAssociatedObjectThread {
    // This is an example of a functional test case.
    NSObject *obj = [NSObject new];
    objc_setAssociatedObject(obj, @selector(testAssociatedObjectThread), @0, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    dispatch_group_t group = dispatch_group_create();
    NSInteger count = 10000;
    for (int i=0; i<=count; i++) {
        dispatch_group_async(group, dispatch_get_global_queue(0, 0), ^{
            
            NSNumber *num = objc_getAssociatedObject(obj, @selector(testAssociatedObjectThread));
            NSInteger result = [num integerValue];
            result++;
            objc_setAssociatedObject(obj, @selector(testAssociatedObjectThread), @(result), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            NSLog(@"--->%ld", i);
        });
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NSLog(@"notify------->");
        NSNumber *result = objc_getAssociatedObject(obj, @selector(testAssociatedObjectThread));
        XCTAssertTrue([result integerValue] != count);

        NOTIFY
    });

    WAIT
}

//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
