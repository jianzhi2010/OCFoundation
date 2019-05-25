//
//  LQLabel.h
//  LQOCFoundation
//
//  Created by liang on 2019/5/21.
//  Copyright © 2019 LQ. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LQLabel : UIView

@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) NSAttributedString *attributedText;


@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) UIColor *textColor;


@property (nonatomic, assign) CGFloat lineSpace;

@end

NS_ASSUME_NONNULL_END
