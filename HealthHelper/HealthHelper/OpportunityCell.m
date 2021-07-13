//
//  OpportunityCell.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/12/21.
//

#import "OpportunityCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation OpportunityCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // Round profile images
    self.profileImageView.layer.cornerRadius = 40;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
