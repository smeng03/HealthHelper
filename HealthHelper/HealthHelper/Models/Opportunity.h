//
//  Opportunity.h
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/14/21.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import "Organization.h"
#import <CoreLocation/CoreLocation.h>

@protocol OpportunityDelegate

- (void)finishOpportunitySetup:(NSMutableArray *)opportunities;

@end

@interface Opportunity : PFObject<PFSubclassing>

@property (nonatomic, strong) NSString *opportunityId;
@property (nonatomic, strong) NSDate *timeCreatedAt;
@property (nonatomic, strong) NSDate *timeUpdatedAt;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, strong) NSString *signUpLink;
@property (nonatomic, strong) NSString *opportunityType;
@property (nonatomic, strong) NSString *position;
@property (nonatomic, strong) Organization *author;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSNumber *hours;
@property (nonatomic, strong) NSNumber *amount;
@property (nonatomic, weak) id<OpportunityDelegate> delegate;


- (void)initOpportunityWithObject:(PFObject *)object withLocationArray:(NSArray *)locationsList withController:controller;
+ (void)createOpportunityArray:(NSArray *)objects withLocation:(CLLocation *)userLocation withController:controller;
    
@end
