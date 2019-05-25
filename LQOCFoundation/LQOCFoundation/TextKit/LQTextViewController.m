//
//  LQTextViewController.m
//  LQOCFoundation
//
//  Created by liang on 2019/5/21.
//  Copyright © 2019 LQ. All rights reserved.
//

#import "LQTextViewController.h"
#import "LQLabel.h"

@interface LQTextViewController ()

@property (nonatomic, strong) LQLabel *label;

@end

@implementation LQTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    
    self.label = [[LQLabel alloc] initWithFrame:CGRectMake(10,200, 300, 300)];
    self.label.text = @"Copyright © 2019 LQ. All rights reserved.";
    self.label.font = [UIFont systemFontOfSize:18];
    self.label.textColor = [UIColor blueColor];
    self.label.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:self.label];
    
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    [self.label setNeedsDisplay];
}

@end
