//
//  ReviewCell.h
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/16/21.
//

#import <UIKit/UIKit.h>
#import "Review.h"

NS_ASSUME_NONNULL_BEGIN

@interface ReviewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *ratingLabel;
@property (weak, nonatomic) IBOutlet UILabel *commentLabel;
@property (strong, nonatomic) Review *review;

- (void)setCell:(Review *)review;

@end

NS_ASSUME_NONNULL_END
