//
//  LQBlockViewController.m
//  LQOCFoundation
//
//  Created by liang on 2019/5/1.
//  Copyright © 2019 LQ. All rights reserved.
//

#import "LQBlockViewController.h"
#import <objc/runtime.h>
#import "LQTestModel.h"

@interface LQBlockViewController ()

@end

@implementation LQBlockViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [LQModelChild new];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
//    [self testGlobalBlock];
    [self testMallocBlock];
//    [self testStackBlock];
    
}

- (void)testGlobalBlock {
    
    static int static_var = 3;
    void (^globalBlock)(void) = ^{
        static_var++;
        NSLog(@"Block var:%d", static_var);
    };
    
    //__NSGlobalBlock__
    NSLog(@"%@", globalBlock);
}

- (void)testMallocBlock {
    NSObject *obj = [NSObject new];
    void (^mallocBlock)(void) = ^{
        NSLog(@"Block obj:%@", obj);
    };
    
    //__NSMallocBlock__
    NSLog(@"%@", mallocBlock);
    
    Class clazz = object_getClass(mallocBlock);
    while (clazz) {
        Class superClazz = class_getSuperclass(clazz);
        NSLog(@"class:%@, superClass:%@", clazz, superClazz);
        
        clazz = superClazz;
    }
}


- (void)testStackBlock {
    
    int var = 3;
    void (^mallocBlock)(void) = ^{
        NSLog(@"Block var:%d", var);
    };
    //__NSMallocBlock__
    NSLog(@"%@", mallocBlock);
    
    
    __block int blockVar = 10;
    //__NSStackBlock__
    NSLog(@"%@", ^{NSLog(@"var: %d %p", blockVar++, &blockVar);});
}


@end
