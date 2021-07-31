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
#import "DateTools.h"

@implementation ReviewCell

- (void)awakeFromNib {
    
    [super awakeFromNib];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    [super setSelected:selected animated:animated];

}

- (void)setCell:(Review *)review {
    
    // Profile image
    PFFileObject *image = review[@"author"][@"image"];
    self.profileImageView.image = nil;
    [self.profileImageView sd_setImageWithURL:[NSURL URLWithString:image.url]];
    self.profileImageView.layer.cornerRadius = 25;
    
    // Username label
    self.usernameLabel.text = review.author[@"username"];
    
    // Sets stars
    [self setStars:review.stars];
    
    // Comment label
    self.commentLabel.text = review.comment;
    
    // Setting review
    self.review = review;
    
    // Setting date label
    self.dateLabel.text = review.timeCreatedAt.shortTimeAgoSinceNow;
    
}

- (void)setStars:(NSNumber *)stars {
    
    if ([stars intValue] == 1) {
        
        self.star1.image = [UIImage imageNamed:@"star-filled"];
        self.star2.image = [UIImage imageNamed:@"star"];
        self.star3.image = [UIImage imageNamed:@"star"];
        self.star4.image = [UIImage imageNamed:@"star"];
        self.star5.image = [UIImage imageNamed:@"star"];
        
    } else if ([stars intValue] == 2) {
        
        self.star1.image = [UIImage imageNamed:@"star-filled"];
        self.star2.image = [UIImage imageNamed:@"star-filled"];
        self.star3.image = [UIImage imageNamed:@"star"];
        self.star4.image = [UIImage imageNamed:@"star"];
        self.star5.image = [UIImage imageNamed:@"star"];
        
    } else if ([stars intValue] == 3) {
        
        self.star1.image = [UIImage imageNamed:@"star-filled"];
        self.star2.image = [UIImage imageNamed:@"star-filled"];
        self.star3.image = [UIImage imageNamed:@"star-filled"];
        self.star4.image = [UIImage imageNamed:@"star"];
        self.star5.image = [UIImage imageNamed:@"star"];
        
    } else if ([stars intValue] == 4) {
        
        self.star1.image = [UIImage imageNamed:@"star-filled"];
        self.star2.image = [UIImage imageNamed:@"star-filled"];
        self.star3.image = [UIImage imageNamed:@"star-filled"];
        self.star4.image = [UIImage imageNamed:@"star-filled"];
        self.star5.image = [UIImage imageNamed:@"star"];
        
    } else if ([stars intValue] == 5) {
        
        self.star1.image = [UIImage imageNamed:@"star-filled"];
        self.star2.image = [UIImage imageNamed:@"star-filled"];
        self.star3.image = [UIImage imageNamed:@"star-filled"];
        self.star4.image = [UIImage imageNamed:@"star-filled"];
        self.star5.image = [UIImage imageNamed:@"star-filled"];
        
    }
    
}


@end
