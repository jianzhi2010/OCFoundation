//
//  LQTestNotificationViewController.m
//  LQOCFoundation
//
//  Created by liang on 2019/4/6.
//  Copyright © 2019 LQ. All rights reserved.
//

#import "LQTestNotificationViewController.h"

@interface LQTestNotificationViewController ()

@property (nonatomic, weak) LQTestNotificationViewController *weakViewController;

@end

@implementation LQTestNotificationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    self.weakViewController = self;
    
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(testNotify:) name:@"test" object:nil];
    //    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(testNotify:) name:@"test" object:nil];
    
    
    //    id __block observer2 = [[NSNotificationCenter defaultCenter] addObserverForName:@"test" object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
    //
    //        NSLog(@"------>%@", note);
    //        NSLog(@"---->%@", observer2);
    //
    //        [[NSNotificationCenter defaultCenter] removeObserver:observer2];
    //    }];
    
    
    id __block observer = [[NSNotificationCenter defaultCenter] addObserverForName:@"test" object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        
        NSLog(@"-->%@", note);
        NSLog(@"-->%@", observer);
        
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }];
    
    
    //    [[NSNotificationCenter defaultCenter] postNotificationName:@"test" object:self];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)testNotify:(NSNotification *)note {
    NSLog(@"-->%@", note);
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    //    LQTestNotificationViewController *vc = [[LQTestNotificationViewController alloc] init];
    //    [self.navigationController pushViewController:vc animated:YES];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"test" object:self];
}

- (void)dealloc {
    NSLog(@"weakSelf:%@", self.weakViewController);
    NSLog(@"self:%@", self);
}


- (void)testPeform {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSLog(@"gcd begin-->");
        [self performSelectorOnMainThread:@selector(mainThreadTest) withObject:self waitUntilDone:NO];
        
        sleep(10);
        NSLog(@"gcd end-->");
        
    });
}

- (void)mainThreadTest {
    NSLog(@"%@ begin", NSStringFromSelector(_cmd));
}


@end
