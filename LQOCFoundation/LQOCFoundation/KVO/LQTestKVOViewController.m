//
//  LQTestKVOViewController.m
//  LQOCFoundation
//
//  Created by liang on 2019/4/14.
//  Copyright © 2019 LQ. All rights reserved.
//

#import "LQTestKVOViewController.h"
#import "LQTestModel.h"
#import <objc/runtime.h>
#import "LQTestUtil.h"

static void *kTestContext = &kTestContext;

@interface LQTestKVOViewController ()

@property (nonatomic, copy) NSString *name;


@end

@implementation LQTestKVOViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
        [self testObserver];
    
//    [self testManualKVO];
    
//    [self testKVODetail];
    
}

- (void)testKVODetail {
    LQModelToy *toy = [[LQModelToy alloc] init];
    
    [LQTestUtil printDescription:@"toy" object:toy];
    
    [toy addObserver:self forKeyPath:@"function" options:NSKeyValueObservingOptionNew context:NULL];

    [LQTestUtil printDescription:@"toy" object:toy];

    [toy removeObserver:self forKeyPath:@"function"];

    [LQTestUtil printDescription:@"toy" object:toy];

    
}


- (void)testObserver {
    
    [self addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [self addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:kTestContext];
    self.name = @"hhxx";
    [self removeObserver:self forKeyPath:@"name"];

}

- (void)testManualKVO{
    
    LQModelParent *parent = [LQModelParent new];
    [parent addObserver:self forKeyPath:@"manualNotifyObject" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    
    parent.manualNotifyObject = @"hhxx";
    
    [parent removeObserver:self forKeyPath:@"manualNotifyObject"];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"keyPath:%@, object:%@, change:%@, context:%p", keyPath, object, change, context);
    
}



@end
