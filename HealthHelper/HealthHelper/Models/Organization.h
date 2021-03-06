//
//  Organization.h
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/14/21.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import <CoreLocation/CoreLocation.h>

@class Organization;

@protocol OrganizationDelegate

- (void)placeMarker:(Organization *)organization;

@end

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
@property (nonatomic, strong) NSNumber *destinationLatValue;
@property (nonatomic, strong) NSNumber *destinationLngValue;
@property (nonatomic, strong) NSString *distance;
@property (nonatomic, assign) NSNumber *distanceValue;
@property (nonatomic, strong) NSString *duration;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, weak) id<OrganizationDelegate> delegate;

+ (Organization *)initOrganizationWithObject:(PFObject *)object withLocationArray:(NSArray *)locationArray withController:controller;
 
    
@end
