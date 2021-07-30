//
//  GMYConfettiView.h
//  GMYConfettiView
//
//  Created by 郭妙友 on 16/1/22.
//  Copyright © 2016年 miaoyou.gmy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GMYConfettiView : UIView

@property (nonatomic, assign) CGFloat intensity;

- (void)startConfetti;
- (void)stopConfetti;

@end
