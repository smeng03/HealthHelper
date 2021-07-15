//
//  Organization.h
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/14/21.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>

@interface Organization : PFObject<PFSubclassing>

@property (nonatomic, strong) NSString *organizationId;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSDate *timeCreatedAt;
@property (nonatomic, strong) NSDate *timeUpdatedAt;
@property (nonatomic, strong) NSString *imageURL;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSNumber *totalScore;
@property (nonatomic, strong) NSNumber *numReviews;
@property (nonatomic, strong) NSArray *reviews;

+ (Organization *)initOrganizationWithObject:(PFObject *)object;
 
    
@end
