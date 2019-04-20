//
//  LQUnitTestUtil.h
//  LQOCFoundation
//
//  Created by liang on 2019/4/20.
//  Copyright © 2019 LQ. All rights reserved.
//

#ifndef LQUnitTestUtil_h
#define LQUnitTestUtil_h

#define WAIT do {\
[self expectationForNotification:@"LQUnitTest" object:nil handler:nil];\
[self waitForExpectationsWithTimeout:30 handler:nil];\
} while (0);
#define NOTIFY \
[[NSNotificationCenter defaultCenter]postNotificationName:@"LQUnitTest" object:nil];

#endif /* LQUnitTestUtil_h */
