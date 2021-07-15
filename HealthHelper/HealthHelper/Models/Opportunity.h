//
//  Opportunity.h
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/14/21.
//

#import <Parse/Parse.h>
#import "Organization.h"

@interface Opportunity

@property (nonatomic, strong) NSString *opportunityId;
@property (nonatomic, strong) NSDate *timeCreatedAt;
@property (nonatomic, strong) NSDate *timeUpdatedAt;
@property (nonatomic, strong) Organization *author;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, strong) NSArray *tags;
@property (nonatomic, strong) NSString *signUpLink;
@property (nonatomic, strong) NSStirng *opportunityType;
    
@end
