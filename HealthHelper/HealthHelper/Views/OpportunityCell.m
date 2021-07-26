//
//  OpportunityCell.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/12/21.
//

#import "OpportunityCell.h"
#import <QuartzCore/QuartzCore.h>
#import "Opportunity.h"
#import "Organization.h"
#import "UIImageView+AFNetworking.h"
#import <SDWebImage/SDWebImage.h>
#import "FBShimmering.h"
#import "FBShimmeringView.h"
#import "FBShimmeringLayer.h"

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

- (void)setCell:(Opportunity *)opportunity {
    // Profile image
    self.profileImageView.image = nil;
    self.profileImageView.alpha = 0;
    [self.profileImageView sd_setImageWithURL:[NSURL URLWithString:opportunity.author.imageURL] placeholderImage:nil options:SDWebImageRetryFailed completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        
        if (image) {
            BOOL animated = NO;

            if (cacheType == SDImageCacheTypeDisk || cacheType == SDImageCacheTypeNone) {
                animated = YES;
            }

            self.profileImageView.image = image;

            if (animated) {
                [UIView animateWithDuration:1 animations:^{
                    self.profileImageView.alpha = 1.0;
                }];

            } else {
                self.profileImageView.alpha = 1.0;
            }
        }

    }];
    
    
    
    // Organization name label
    self.organizationNameLabel.text = opportunity.author.username;
    
    // Description label
    self.descriptionLabel.text = opportunity.text;
    
    // Position label
    self.positionLabel.text = [NSString stringWithFormat:@"Position: %@", opportunity.position];
    
    // Type label
    self.typeLabel.text = [NSString stringWithFormat:@"Type: %@", opportunity.opportunityType];
    
    // Setting opportunity
    self.opportunity = opportunity;
}

@end
