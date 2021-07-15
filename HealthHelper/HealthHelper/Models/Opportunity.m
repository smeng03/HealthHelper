//
//  Opportunity.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/14/21.
//

#import <Foundation/Foundation.h>
#import "Opportunity.h"
#import "Organization.h"

@implementation Opportunity

@dynamic opportunityId;
@dynamic timeCreatedAt;
@dynamic timeUpdatedAt;
//@dynamic author;
@dynamic text;
@dynamic tags;
@dynamic signUpLink;
@dynamic opportunityType;
@dynamic position;
@dynamic imageURL;
@dynamic username;

+ (nonnull NSString *)parseClassName {
    return @"Opportunity";
}

- (void)initOpportunityWithObject:(PFObject *)object {
    // Setting Opportunity object given PFObject
    self.text = object[@"description"];
    self.tags = object[@"tags"];
    self.signUpLink = object[@"signUpLink"];
    self.opportunityType = object[@"opportunityType"];
    self.position = object[@"position"];
    self.opportunityId = object.objectId;
    self.timeCreatedAt = object.createdAt;
    self.timeUpdatedAt = object.updatedAt;
    PFObject *author = object[@"author"];
    //self.author = [Organization new];
    //self.author.text = author[@"description"];
    //self.author.address = author[@"address"];
    PFFileObject *image = author[@"image"];
    self.imageURL = image.url;
    self.username = author[@"username"];
    //self.author.totalScore = author[@"totalScore"];
    //self.author.numReviews = author[@"numReviews"];
    //self.author.reviews = author[@"reviews"];
    //self.author.organizationId = author.objectId;
    //self.author.timeCreatedAt = author.createdAt;
    //self.author.timeUpdatedAt = author.updatedAt;
}

+ (NSMutableArray *)createOpportunityArray:(NSArray *)objects {
    // Returns array of Opportunity objects given array of PFObjects
    NSMutableArray *newOpportunities = [[NSMutableArray alloc] init];
    for (PFObject *opportunity in objects) {
        Opportunity *newOpportunity = [Opportunity new];
        [newOpportunity initOpportunityWithObject:opportunity];
        [newOpportunities addObject:newOpportunity];
    }
    return newOpportunities;
}
    
@end




