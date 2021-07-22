//
//  ProfileViewController.h
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/12/21.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ProfileViewController : UIViewController <CLLocationManagerDelegate>

- (void)placeMarkers;

@end

NS_ASSUME_NONNULL_END
