//
//  OpportunityCell.h
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/12/21.
//

#import <UIKit/UIKit.h>
#import "Opportunity.h"
#import "FBShimmering.h"
#import "FBShimmeringView.h"
#import "FBShimmeringLayer.h"

NS_ASSUME_NONNULL_BEGIN

@protocol OpportunityCellDelegate

- (void)didTapOrganizationProfile:(Opportunity *)opportunity;

@end

@interface OpportunityCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *organizationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *positionLabel;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (strong, nonatomic) Opportunity *opportunity;
@property (strong, nonatomic) FBShimmeringView *shimmeringView;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak) id<OpportunityCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIView *containerView;

- (void)setCell:(Opportunity *)opportunity withDelegate:controller;

@end

NS_ASSUME_NONNULL_END
