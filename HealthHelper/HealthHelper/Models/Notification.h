//
//  Notification.h
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/28/21.
//

@interface Notification : NSObject

+ (void)successNotificationAction:(UIView *)view withLabel:(UILabel *)label;
+ (void)failureNotificationAction:(UIView *)view withLabel:(UILabel *)label;
+ (void)hideNotificationAction:(UIView *)view;

@end
