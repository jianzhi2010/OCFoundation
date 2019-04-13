//
//  LQTestModelViewController.m
//  LQOCFoundation
//
//  Created by liang on 2019/3/27.
//  Copyright © 2019 LQ. All rights reserved.
//

#import "LQTestModelViewController.h"
#import <objc/runtime.h>
#import <objc/message.h>

@interface LQTestModelViewController ()

@property (nonatomic, assign) float count;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) void (^myBlock)(NSString *desc);

@end

@implementation LQTestModelViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor whiteColor];
    
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    //    [self test];
    
    
    //    for (int i=0; i<10000; i++) {
    //        dispatch_async(dispatch_get_global_queue(0, 0), ^{
    //            [self createObject];
    //        });
    //    }
    
//    [self testPeform];
    
//    [self testNSObject];
    
    [self testBlock];
    
}

- (void)testBlock {
    self.myBlock = NULL;
    
    void (^block)(void)  = ^(void){
        NSLog(@"block..");
    };
    ((void (*)(id, SEL, void(^)(void)))(void *) objc_msgSend)((id)self, @selector(setMyBlock:), block);
    NSLog(@"%@->%@", NSStringFromSelector(_cmd), self.myBlock);
    
    Class nsBlockClass = [(NSObject *)block class];
    NSLog(@"nsBlockClass:%@", nsBlockClass);

}

- (void)testNSObject {
    NSObject *obj = [NSObject new];
    
    Class class = class_getSuperclass(obj.class);
    NSLog(@"-->%@", class);
    
}

- (void)testClass {
    Class instanceClass = [self class];
    Class classClass = [LQTestModelViewController class];
    NSLog(@"is:%@", instanceClass == classClass ? @"true" : @"false");
    
    
    Class objClazz = [LQTestModelViewController class];
    Class objMetaClazz = objc_getMetaClass(class_getName(objClazz));
    Class objectClazz = object_getClass(self);
    Class objectMetaClazz = object_getClass(objClazz);
    NSLog(@"class:%@", objClazz == objectClazz ? @"true" : @"false");
    
    NSLog(@"metaClass:%@", objMetaClazz == objectMetaClazz ? @"true" : @"false");
}


- (void)testPeform {
    
    [self performSelector:@selector(setName:) withObject:@"hh"];
    NSLog(@"name--->%@", self.name);
    
    [self performSelector:@selector(setCount:) withObject:@33.5];
    NSLog(@"count--->%.1f", self.count);
    
    ((void (*)(id, SEL, float))(void *) objc_msgSend)((id)self, @selector(setCount:), 33.5);
    NSLog(@"count----->%.1f", self.count);
    
    [self.class performSelector:@selector(testClassMethod:) withObject:self];
}

+ (void)testClassMethod:(NSObject *)obj {
    NSLog(@"%@-->%@", NSStringFromSelector(_cmd), obj);
}

- (void)createObject {
    static NSMutableDictionary *cache;
    static dispatch_semaphore_t lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [NSMutableDictionary dictionary];
        lock = dispatch_semaphore_create(1);
    });
    
    dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
    NSObject *info = [cache objectForKey:@"lq"];
    dispatch_semaphore_signal(lock);
    
    if (!info) {
        info = [[NSObject alloc] init];
        if (info) {
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
            NSLog(@"create--->");
            [cache setObject:info forKey:@"lq"];
            dispatch_semaphore_signal(lock);
        }
    }
}

- (void)test {
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_global_queue(0,0), ^{
        NSLog(@"signal...");
        dispatch_semaphore_signal(semaphore);
    });
    
    NSLog(@"wait...");
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    NSLog(@"end...");
}

@end
