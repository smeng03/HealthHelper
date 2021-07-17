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
    self.profileImageView.layer.cornerRadius = 40;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setCell:(Opportunity *)opportunity {
    // Profile image
    self.profileImageView.image = nil;
    [self.profileImageView sd_setImageWithURL:[NSURL URLWithString:opportunity.author.imageURL]];
    
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
        self.metricsLabel.text = [NSString stringWithFormat:@"Hours volunteered: $%@", opportunity.hours];
    } else if ([opportunity.opportunityType isEqualToString:@"Shadowing"]) {
        self.metricsLabel.text = [NSString stringWithFormat:@"Hours shadowed: $%@", opportunity.hours];
    }
    
    // Setting opportunity
    self.opportunity = opportunity;
}

@end
