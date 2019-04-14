//
//  LQTestModel.h
//  LQOCFoundation
//
//  Created by liang on 2019/4/14.
//  Copyright © 2019 LQ. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LQTestModel.h"


@interface LQModelParent : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, assign) NSInteger age;
@property (nonatomic, assign) double weight;

@property (nonatomic, copy) NSString *manualNotifyObject;

@end



@interface LQModelToy : NSObject

@property (nonatomic, copy) NSString *function;
@property (nonatomic, assign) double price;

@end


@interface LQModelChild : LQModelParent

@property (nonatomic, strong) LQModelParent *father;
@property (nonatomic, strong) LQModelParent *mother;
@property (nonatomic, strong) NSArray<LQModelToy *> *toys;

@property (nonatomic, copy) NSString *status;
@property (nonatomic, copy) NSString *nickName;

@end
