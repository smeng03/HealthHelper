//
//  GMYConfettiView.m
//  GMYConfettiView
//
//  Created by 郭妙友 on 16/1/22.
//  Copyright © 2016年 miaoyou.gmy. All rights reserved.
//

#import "GMYConfettiView.h"

@interface GMYConfettiView ()
@property (nonatomic, strong) NSArray *colors;
@property (nonatomic, strong) UIImage *customImg;
@property (nonatomic, strong) CAEmitterLayer *emitter;
@end

@implementation GMYConfettiView

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    return [super initWithCoder:aDecoder];
}

- (instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        _colors = @[[UIColor colorWithRed:.95 green:.4 blue:.27 alpha:1.],
                    [UIColor colorWithRed:1. green:.78 blue:.36 alpha:1.],
                    [UIColor colorWithRed:.48 green:.78 blue:.64 alpha:1.],
                    [UIColor colorWithRed:.3 green:.76 blue:.85 alpha:1.],
                    [UIColor colorWithRed:.58 green:.39 blue:.55 alpha:1.]];
        
        _intensity = 1.0f;
        
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}


#pragma mark - Configuring confetti cells

- (CAEmitterCell *)configConfettiWithColor:(UIColor *)color{
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    cell.birthRate = 6.0 * self.intensity;
    cell.lifetime = 14.0 * self.intensity;
    cell.lifetimeRange = 0;
    cell.color = color.CGColor;
    cell.velocity = 600.0 * self.intensity;
    cell.velocityRange = 80.0 * self.intensity;
    cell.emissionLongitude = M_PI;
    cell.emissionRange = M_PI_4;
    cell.spin = 3.5 * self.intensity;
    cell.spinRange = 4.0 * self.intensity;
    cell.scale = 0.3;
    cell.scaleRange = 0.15;
    cell.scaleSpeed = -0.1 * self.intensity;
    cell.contents = (__bridge id)([UIImage imageNamed:@"confetti"].CGImage);
    return cell;
}

- (void)startConfetti{
    self.emitter = [CAEmitterLayer layer];
    self.emitter.emitterPosition = CGPointMake(self.center.x, 0);
    self.emitter.emitterShape = kCAEmitterLayerLine;
    self.emitter.emitterSize = CGSizeMake(self.frame.size.width, 0);
    
    
    NSMutableArray *cells = [NSMutableArray arrayWithCapacity:self.colors.count];
    [self.colors enumerateObjectsUsingBlock:^(UIColor *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [cells addObject:[self configConfettiWithColor:obj]];
    }];
    
    self.emitter.emitterCells = [cells copy];
    
    [self.layer addSublayer:self.emitter];
}

- (void)stopConfetti{
    self.emitter.birthRate = 0.f;
}

@end
