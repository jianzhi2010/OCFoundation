//
//  AppDelegate.m
//  LQOCFoundation
//
//  Created by liang on 2019/3/27.
//  Copyright © 2019 LQ. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (void)test:(NSNotification *)noti {
//    NSLog(@"noti:%@", noti);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
#if DEBUG
    [[NSBundle bundleWithPath:@"/Applications/InjectionIII.app/Contents/Resources/iOSInjection10.bundle"] load];
    
    NSBundle *bundle = [NSBundle bundleWithPath:@"/Users/Lam/Library/Developer/Xcode/DerivedData/InjectionIII-dklavftdhsdwhwdxfguwltyyglko/Build/Products/Debug/InjectionIII.app/Contents/Resources/iOSInjection10.bundle"];
//    bundle = [NSBundle bundleWithPath:@"/Users/Lam/Library/Developer/Xcode/DerivedData/InjectionIII-dklavftdhsdwhwdxfguwltyyglko/Build/Products/Debug/macOSInjection.bundle"];
    if (bundle) {
//       BOOL suc = [bundle load];
//        NSLog(@"-->%d",suc);
    }
#endif
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(test:) name:nil object:nil];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
