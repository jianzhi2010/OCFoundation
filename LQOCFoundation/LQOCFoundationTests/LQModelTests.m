//
//  LQModelTests.m
//  LQOCFoundationTests
//
//  Created by liang on 2019/4/6.
//  Copyright © 2019 LQ. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSObject+LQModel.h"
#import "LQTestModel.h"


@interface LQModelTests : XCTestCase

@end

@implementation LQModelTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testJsonToModel {
    
    NSDictionary *dict = @{
                           @"name" : @"LQ",
                           @"age" : @18,
                           @"weight" : @"100.5",
                           @"nick" : @"Lee",
                           @"father" : @{
                                   @"name" : @"L",
                                   @"age" : @38,
                                   @"weight" : @"110.5",
                                   },
                           @"mother" : @{
                                   @"name" : @"Q",
                                   @"age" : @30,
                                   @"weight" : @100,
                                   },
                           @"toys" : @[
                                        @{
                                           @"function" : @"sing",
                                           @"price" : @99.9,
                                        },
                                       ],
                           @"ext"  : @{
                                   @"s" : @"happy",
                                   },
                           @"exclude" : @"*",
                           };
    
    LQModelChild *child = [LQModelChild modelWithJSON:dict];
    XCTAssertTrue(child.age == 18);
    XCTAssertEqual(child.name, @"LQ");
    XCTAssertTrue(child.weight == 100.5);
    XCTAssertEqual(child.nickName, @"Lee");
    XCTAssertEqual(child.status, @"happy");

    XCTAssertTrue(child.father.age == 38);
    XCTAssertEqual(child.father.name, @"L");
    XCTAssertTrue(child.father.weight == 110.5);
    XCTAssertTrue(child.mother.age == 30);
    XCTAssertEqual(child.mother.name, @"Q");
    XCTAssertTrue(child.mother.weight == 100);

    XCTAssertTrue(child.toys.firstObject.price == 99.9);
    XCTAssertEqual(child.toys.firstObject.function, @"sing");

}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
