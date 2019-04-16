//
//  LQKVOTests.m
//  LQOCFoundationTests
//
//  Created by liang on 2019/4/14.
//  Copyright © 2019 LQ. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSObject+LQKeyValueObserving.h"
#import "LQTestModel.h"

@interface LQKVOTests : XCTestCase

@end

@implementation LQKVOTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testAddKVO {
    
    LQModelToy *toy = [LQModelToy new];
    [toy lq_addObserver:self forKeyPath:@"function" options:NSKeyValueObservingOptionNew context:NULL];
    [toy lq_addObserver:self forKeyPath:@"function" options:NSKeyValueObservingOptionNew context:NULL];
    [toy lq_addObserver:self forKeyPath:@"price" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    toy.function = @"test";
    toy.price = 9.9;
    
    [toy lq_removeObserver:self forKeyPath:@"price"];
    
    XCTAssertEqual(toy.function, @"test");
    
}

- (void)testRemoveKVO {
    LQModelToy *toy = [LQModelToy new];

    [toy lq_addObserver:self forKeyPath:@"function" options:NSKeyValueObservingOptionNew context:NULL];
    [toy lq_removeObserver:self forKeyPath:@"price"];

}

- (void)testCategory {
    
    NSObject *object = [NSObject new];
    // call category method...
    [object lq_observeValueForKeyPath:@"tt" ofObject:nil change:nil context:nil];
}


- (void)lq_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {

    if ([keyPath isEqualToString:@"function"]) {
        id newValue = change[NSKeyValueChangeNewKey];
        XCTAssertEqual(newValue, @"test");
    } else if ([keyPath isEqualToString:@"price"]) {
        id newValue = change[NSKeyValueChangeNewKey];
        XCTAssertTrue([newValue doubleValue] == 9.9);
    }

}


- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
