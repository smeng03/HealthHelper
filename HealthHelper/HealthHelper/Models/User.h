//
//  User.h
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/12/21.
//

#import <Parse/Parse.h>

@interface User : PFUser<PFSubclassing>

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSDate *timeCreatedAt;
@property (nonatomic, strong) NSDate *timeUpdatedAt;
@property (nonatomic, strong) NSString *imageURL;
@property (nonatomic, strong) NSNumber *amountDonated;
@property (nonatomic, strong) NSArray *pastVolunteerOps;
@property (nonatomic, strong) NSArray *pastDonations;
@property (nonatomic, strong) NSArray *pastShadowingOps;
@property (nonatomic, strong) NSArray *reviews;
    
@end
