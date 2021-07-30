//
//  DetailsViewController.h
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/12/21.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "Opportunity.h"

NS_ASSUME_NONNULL_BEGIN

@interface DetailsViewController : UIViewController

@property (nonatomic, strong) Opportunity *opportunity;
@property (nonatomic, strong) CLLocation *userLocation;

@end

NS_ASSUME_NONNULL_END
