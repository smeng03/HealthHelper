//
//  ReviewCell.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/16/21.
//

#import <QuartzCore/QuartzCore.h>
#import "ReviewCell.h"
#import <SDWebImage/SDWebImage.h>
#import "UIImageView+AFNetworking.h"
#import "Review.h"

@implementation ReviewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setCell:(Review *)review {
    // Profile image
    PFFileObject *image = review[@"author"][@"image"];
    self.profileImageView.image = nil;
    [self.profileImageView sd_setImageWithURL:[NSURL URLWithString:image.url]];
    self.profileImageView.layer.cornerRadius = 25;
    
    // Username label
    self.usernameLabel.text = review.author[@"username"];
    
    // Rating label
    self.ratingLabel.text = [NSString stringWithFormat:@"Rating: %@/5", review.stars];
    
    // Comment label
    self.commentLabel.text = review.comment;
    
    // Setting review
    self.review = review;
}


@end
