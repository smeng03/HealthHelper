//
//  Notification.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/28/21.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "Notification.h"

@implementation Notification

+ (void)successNotificationAction:(UIView *)view withLabel:(UILabel *)label {
    
    // Display success message with animation
    [view setHidden:NO];
    view.backgroundColor = [UIColor colorNamed:@"successColor"];
    view.layer.cornerRadius = 10;
    label.textColor = [UIColor whiteColor];
    label.text = @"Your review was successfully posted!";
    
    view.alpha = 0;
    [UIView animateWithDuration:1 delay:0 options: 0 animations:^{
       view.alpha = 1;
    } completion: nil];
    
}

+ (void)failureNotificationAction:(UIView *)view withLabel:(UILabel *)label {
    
    // Display failure message with animation
    [view setHidden:NO];
    view.backgroundColor = [UIColor colorNamed:@"failColor"];
    view.layer.cornerRadius = 10;
    label.textColor = [UIColor whiteColor];
    label.text = @"Error! Your review failed to post.";
    
    view.alpha = 0;
    [UIView animateWithDuration:1 delay:0 options: 0 animations:^{
       view.alpha = 1;
    } completion: nil];
    
}

+ (void)hideNotificationAction:(UIView *)view {
     
    // Hide message with animation
    view.alpha = 1;
    [UIView animateWithDuration:1 delay:5 options: 0 animations:^{
       view.alpha = 0;
    } completion: ^(BOOL finished){
        view.hidden = YES;
    }];
    
}

@end
