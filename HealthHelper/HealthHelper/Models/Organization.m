//
//  Organization.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/14/21.
//

#import <Foundation/Foundation.h>
#import "Organization.h"

@implementation Organization

@dynamic organizationId;
@dynamic timeCreatedAt;
@dynamic timeUpdatedAt;
@dynamic username;
@dynamic text;
@dynamic address;
@dynamic imageURL;
@dynamic totalScore;
@dynamic numReviews;
@dynamic reviews;

+ (nonnull NSString *)parseClassName {
    return @"Organization";
}

+ (Organization *)initOrganizationWithObject:(PFObject *)object {
    // Setting Organization object given PFObject
    Organization *organization = [Organization new];
    organization.text = object[@"description"];
    organization.address = object[@"address"];
    PFFileObject *image = object[@"image"];
    organization.imageURL = image.url;
    organization.totalScore = object[@"totalScore"];
    organization.numReviews = object[@"numReviews"];
    organization.reviews = object[@"reviews"];
    organization.username = object[@"username"];
    organization.organizationId = object.objectId;
    organization.timeCreatedAt = object.createdAt;
    organization.timeUpdatedAt = object.updatedAt;
    
    return organization;
}
    
@end
