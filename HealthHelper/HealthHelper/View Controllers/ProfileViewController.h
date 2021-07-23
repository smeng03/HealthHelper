//
//  ProfileViewController.h
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/12/21.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "Organization.h"

NS_ASSUME_NONNULL_BEGIN

@interface ProfileViewController : UIViewController <CLLocationManagerDelegate>

- (void)placeMarker:(Organization *)organization;

@end

NS_ASSUME_NONNULL_END
