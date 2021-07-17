//
//  PastOpportunityCell.h
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/12/21.
//

#import <UIKit/UIKit.h>
#import "Opportunity.h"

NS_ASSUME_NONNULL_BEGIN

@interface PastOpportunityCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *organizationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *metricsLabel;
@property (strong, nonatomic) Opportunity *opportunity;

- (void)setCell:(Opportunity *)opportunity;

@end

NS_ASSUME_NONNULL_END
