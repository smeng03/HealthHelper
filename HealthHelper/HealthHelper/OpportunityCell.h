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

@interface OpportunityCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *organizationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UILabel *positionLabel;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (strong, nonatomic) Opportunity *opportunity;
@property (strong, nonatomic) FBShimmeringView *shimmeringView;

- (void)setCell:(Opportunity *)opportunity;

@end

NS_ASSUME_NONNULL_END
