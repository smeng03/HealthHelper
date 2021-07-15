//
//  Opportunity.h
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/14/21.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import "Organization.h"

@interface Opportunity : PFObject<PFSubclassing>

@property (nonatomic, strong) NSString *opportunityId;
@property (nonatomic, strong) NSDate *timeCreatedAt;
@property (nonatomic, strong) NSDate *timeUpdatedAt;
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, strong) NSString *signUpLink;
@property (nonatomic, strong) NSString *opportunityType;
@property (nonatomic, strong) NSString *position;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *imageURL;
//@property (nonatomic, strong) Organization *author;

- (void)initOpportunityWithObject:(PFObject *)object;
+ (NSMutableArray *)createOpportunityArray:(NSArray *)objects;
    
@end
