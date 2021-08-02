//
//  PastOpportunityCell.h
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/12/21.
//

#import <UIKit/UIKit.h>
#import "Opportunity.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PastOpportunityCellDelegate

- (void)didTapOrganizationProfile:(Opportunity *)opportunity;

@end

@interface PastOpportunityCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *organizationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *metricsLabel;
@property (strong, nonatomic) Opportunity *opportunity;
@property (nonatomic, weak) id<PastOpportunityCellDelegate> delegate;


- (void)setCell:(Opportunity *)opportunity withDelegate:controller;

@end

NS_ASSUME_NONNULL_END
