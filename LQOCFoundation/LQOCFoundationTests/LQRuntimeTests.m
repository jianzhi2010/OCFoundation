//
//  LQRuntimeTests.m
//  LQOCFoundationTests
//
//  Created by liang on 2019/4/20.
//  Copyright © 2019 LQ. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "LQTestModel.h"

@interface LQRuntimeTests : XCTestCase

@end

@implementation LQRuntimeTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testClass {

    BOOL res1 = [[NSObject class] isKindOfClass:[NSObject class]];
    BOOL res2 = [[NSObject class] isMemberOfClass:[NSObject class]];
    BOOL res3 = [[LQModelToy class] isKindOfClass:[LQModelToy class]];
    BOOL res4 = [[LQModelToy class] isMemberOfClass:[LQModelToy class]];
    
    // +[XX isKindOfClass:xx] 类方法，会用当前类对象的isa指针指向的对象（也就是元类）与传入的class做比较
    // +[XX isMemberOfClass:xx] 类方法，会先用当前类对象的isa指针指向的对象（也就是元类）与传入的class做比较，如果不等就会不停地获取superClass对比

    // [NSObject class]返回self，获取的还是类对象

    //第一次 NSObject元类 与 NSObject类对象比较，不相等
    //第二次找到 NSObject元类的superClass (NSObject的元类的superClass指向NSObject类对象) 所以相等
    XCTAssertTrue(res1);
    XCTAssertFalse(res2);
    
    //元类与类对象比较，不可能相等
    XCTAssertFalse(res3);
    XCTAssertFalse(res4);
    
}


@end
