//
//  ComposeViewController.h
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/14/21.
//

#import <UIKit/UIKit.h>
#import "Opportunity.h"

NS_ASSUME_NONNULL_BEGIN

@protocol ComposeViewControllerDelegate

- (void)didPost;

@end

@interface ComposeViewController : UIViewController

@property (nonatomic, strong) Opportunity *opportunity;
@property (nonatomic, weak) id<ComposeViewControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
