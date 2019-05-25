//
//  LQLabel.m
//  LQOCFoundation
//
//  Created by liang on 2019/5/21.
//  Copyright © 2019 LQ. All rights reserved.
//

#import "LQLabel.h"
#import <CoreText/CoreText.h>


@interface LQLabel() <UIGestureRecognizerDelegate>





@end


@implementation LQLabel



- (void)drawRect:(CGRect)rect {
    // Drawing code

    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
//    CGAffineTransform flipVertical = CGAffineTransformMake(1,0,0,-1,0,self.bounds.size.height);
//    CGContextConcatCTM(context, flipVertical);
    
    NSMutableAttributedString *attrString = nil;
    if (self.attributedText.length) {
        attrString = [[NSMutableAttributedString alloc] initWithAttributedString:self.attributedText];
    } else {
        attrString = [[NSMutableAttributedString alloc] initWithString:self.text];
        
        if (self.font) {
            [attrString addAttribute:NSFontAttributeName value:self.font range:NSMakeRange(0, attrString.length)];
        }
        if (self.textColor) {
            [attrString addAttribute:NSForegroundColorAttributeName value:self.textColor range:NSMakeRange(0, attrString.length)];
        }
    }
    
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attrString);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);
//    [[UIColor redColor] set];
//    CGContextFillRect(context, self.bounds);
    
    CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, attrString.length), path, NULL);
    
    CFArrayRef lines = CTFrameGetLines(frame);
    CFIndex lineCount = CFArrayGetCount(lines);
    
    CGPoint origins[lineCount];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), origins);
    for (CFIndex i=0; i<lineCount; i++) {
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        
        CGPoint lineOrigin = origins[i];
        
        //遍历每一行CTLine
        CGFloat lineAscent;
        CGFloat lineDescent;
        CGFloat lineLeading; // 行距
        // 该函数除了会设置好ascent,descent,leading之外，还会返回这行的宽度
        CGFloat lineWidth = CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
        NSLog(@"lineAscent = %f",lineAscent);
        NSLog(@"lineDescent = %f",lineDescent);
        NSLog(@"lineLeading = %f",lineLeading);
        NSLog(@"lineHeight = %f",lineWidth);

        CGRect oldLineBounds = CTLineGetImageBounds(line, context);

        NSLog(@"lineBounds:%@", NSStringFromCGRect(oldLineBounds));
        NSLog(@"point=%@", NSStringFromCGPoint(lineOrigin));
        

        CGContextSetTextPosition(context, lineOrigin.x, lineOrigin.y-lineDescent);
        
        CGRect lineBounds = CTLineGetImageBounds(line, context);
        NSLog(@"after lineBounds:%@", NSStringFromCGRect(lineBounds));
        
        CGContextSetLineWidth(context, 1.0);
        CGContextAddRect(context, lineBounds);
        CGContextSetStrokeColorWithColor(context, [UIColor greenColor].CGColor);
        CGContextStrokeRect(context, lineBounds);
        
        
        CTLineDraw(line, context);//绘制原点为左下角
        
    }
    
    
    
//    CTFrameDraw(frame, context);
    
    
    
    CFRelease(frame);
    CFRelease(path);
    CFRelease(frameSetter);
    
    
}

@end
