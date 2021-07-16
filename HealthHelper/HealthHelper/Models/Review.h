//
//  Review.h
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/14/21.
//

#import <Parse/Parse.h>
#import "User.h"

@interface Review : PFObject<PFSubclassing>

@property (nonatomic, strong) NSString *reviewId;
@property (nonatomic, strong) NSDate *timeCreatedAt;
@property (nonatomic, strong) NSDate *timeUpdatedAt;
@property (nonatomic, strong) PFUser *author;
@property (nonatomic, strong) NSString *comment;
@property (nonatomic, strong) NSNumber *stars;

- (void)initReviewWithObject:(PFObject *)object;
+ (NSMutableArray *)createReviewArray:(NSArray *)objects;
    
@end
