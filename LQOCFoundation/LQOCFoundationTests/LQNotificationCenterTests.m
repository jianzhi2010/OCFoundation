//
//  LQNotificationCenterTests.m
//  LQOCFoundationTests
//
//  Created by liang on 2019/4/6.
//  Copyright © 2019 LQ. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "LQNotificationCenter.h"
#import "LQNotification.h"

#define WAIT do {\
[self expectationForNotification:@"LQUnitTest" object:nil handler:nil];\
[self waitForExpectationsWithTimeout:30 handler:nil];\
} while (0);
#define NOTIFY \
[[NSNotificationCenter defaultCenter]postNotificationName:@"LQUnitTest" object:nil];

@interface LQNotificationCenterTests : XCTestCase

@end

@implementation LQNotificationCenterTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testPost {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    
    [[LQNotificationCenter defaultCenter] addObserver:self selector:@selector(testNotify:) name:@"testPost" object:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[LQNotificationCenter defaultCenter] postNotificationName:@"testPost" object:nil userInfo:nil];
    });
    
    WAIT
}

- (void)testNotify:(NSNotification *)noti {
    XCTAssertEqual(noti.name, @"testPost");
    
    NOTIFY
}

- (void)testPostBlock {
    [[LQNotificationCenter defaultCenter] addObserverForName:@"testPostBlock" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(LQNotification * _Nonnull note) {
        
        XCTAssertEqual(note.name, @"testPostBlock");
        
        NOTIFY;
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[LQNotificationCenter defaultCenter] postNotificationName:@"testPostBlock" object:nil userInfo:nil];
    });
    
    WAIT
}


- (void)testRemoveObserver {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    [[LQNotificationCenter defaultCenter] addObserver:self selector:@selector(testRemoveObserver:) name:@"testRemoveObserver" object:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[LQNotificationCenter defaultCenter] removeObserver:self name:@"testRemoveObserver" object:nil];
        [[LQNotificationCenter defaultCenter] postNotificationName:@"testRemoveObserver" object:nil userInfo:nil];
        
        [[LQNotificationCenter defaultCenter] addObserver:self selector:@selector(testRemoveObserver:) name:@"testRemoveObserver" object:nil];
        [[LQNotificationCenter defaultCenter] removeObserver:self name:nil object:nil];
        [[LQNotificationCenter defaultCenter] postNotificationName:@"test" object:nil userInfo:nil];
        NOTIFY
    });
    
    WAIT
}

- (void)testRemoveObserver:(NSNotification *)noti {
    XCTAssertTrue(false, @"should not receive the notification");
}


- (void)testAutoRemoveObserver {
    
    NSObject *obserber = [NSObject new];
    [[LQNotificationCenter defaultCenter] addObserver:obserber selector:@selector(testRemoveObserver:) name:@"testRemoveObserver" object:nil];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[LQNotificationCenter defaultCenter] postNotificationName:@"testRemoveObserver" object:nil userInfo:nil];
        NOTIFY
    });
    
    WAIT
}

- (void)testBackgroundObserver {
    dispatch_group_t group = dispatch_group_create();
    
    for (int i=0; i<4000; i++) {
        
        NSString *name = [NSString stringWithFormat:@"testBackgroundObserver%dd", i];
        
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [[LQNotificationCenter defaultCenter] addObserver:self selector:@selector(notifyBackground) name:name object:nil];
        });
        
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[LQNotificationCenter defaultCenter] removeObserver:self name:name object:nil];
        });
        
        dispatch_group_async(group, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[LQNotificationCenter defaultCenter] postNotificationName:name object:nil userInfo:nil];
        });
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        NOTIFY
    });
    
    WAIT
}

- (void)notifyBackground {
    
}

@end
