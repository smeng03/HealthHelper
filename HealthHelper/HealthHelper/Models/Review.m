//
//  Review.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/14/21.
//

#import <Foundation/Foundation.h>
#import "Review.h"

@implementation Review

@dynamic reviewId;
@dynamic timeCreatedAt;
@dynamic timeUpdatedAt;
@dynamic author;
@dynamic comment;
@dynamic stars;

+ (nonnull NSString *)parseClassName {
    return @"Review";
}

- (void)initReviewWithObject:(PFObject *)object {
    // Setting Review object given PFObject
    self.comment = object[@"comment"];
    self.stars = object[@"stars"];
    self.reviewId = object.objectId;
    self.timeCreatedAt = object.createdAt;
    self.timeUpdatedAt = object.updatedAt;
    self.author = object[@"author"];
}

+ (NSMutableArray *)createReviewArray:(NSArray *)objects {
    // Returns array of Opportunity objects given array of PFObjects
    NSMutableArray *newReviews = [[NSMutableArray alloc] init];
    for (PFObject *review in objects) {
        Review *newReview = [Review new];
        [newReview initReviewWithObject:review];
        [newReviews addObject:newReview];
    }
    return newReviews;
}
    
@end
