//
//  PastOpportunityCell.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/12/21.
//

#import "PastOpportunityCell.h"
#import <QuartzCore/QuartzCore.h>
#import <SDWebImage/SDWebImage.h>
#import "UIImageView+AFNetworking.h"

@implementation PastOpportunityCell

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
    // Round profile images
    self.profileImageView.layer.cornerRadius = 30;
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];

}

- (void)setCell:(Opportunity *)opportunity withDelegate:(id)controller {
    
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
    
    // Date label
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterLongStyle;
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    NSString *dateText = [dateFormatter stringFromDate:opportunity.date];
    self.dateLabel.text = [NSString stringWithFormat:@"Date: %@", dateText];
    
    // Metrics label
    if ([opportunity.opportunityType isEqualToString:@"Donation"]) {
        self.metricsLabel.text = [NSString stringWithFormat:@"Amount donated: $%@", opportunity.amount];
    } else if ([opportunity.opportunityType isEqualToString:@"Volunteering"]) {
        self.metricsLabel.text = [NSString stringWithFormat:@"Hours volunteered: %@", opportunity.hours];
    } else if ([opportunity.opportunityType isEqualToString:@"Shadowing"]) {
        self.metricsLabel.text = [NSString stringWithFormat:@"Hours shadowed: %@", opportunity.hours];
    }
    
    // Setting opportunity
    self.opportunity = opportunity;
    
    // Setting tap gesture recognizer
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapOrganizationProfile)];
    [self.profileImageView addGestureRecognizer:tapGestureRecognizer];
    self.delegate = controller;
    
    // Container view
    self.containerView.layer.cornerRadius = 25;
    self.containerView.backgroundColor = [UIColor colorNamed:@"cellColor"];
    self.containerView.layer.shadowOffset = CGSizeMake(0, 2);
    self.containerView.layer.shadowRadius = 5;
    self.containerView.layer.shadowOpacity = 0.2;
    self.backgroundColor = [UIColor colorNamed:@"backgroundColor"];
    
}

- (void)didTapOrganizationProfile {
    [self.delegate didTapOrganizationProfile:self.opportunity];
}

@end
