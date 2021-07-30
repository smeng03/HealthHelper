//
//  Organization.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/14/21.
//

#import <Foundation/Foundation.h>
#import "Organization.h"
#import "ProfileViewController.h"

@interface Organization() <NSDiscardableContent>

@end

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
@dynamic destinationLatValue;
@dynamic destinationLngValue;
@dynamic distance;
@dynamic distanceValue;
@dynamic delegate;
@dynamic duration;

+ (nonnull NSString *)parseClassName {
    return @"Organization";
}


#pragma mark - Initialize Organization object

+ (Organization *)initOrganizationWithObject:(PFObject *)object withLocationArray:(NSArray *)locationArray withController:controller {
    
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
    organization.destinationLatValue = locationArray[0];
    organization.destinationLngValue = locationArray[1];
    organization.distance = locationArray[2];
    organization.distanceValue = locationArray[3];
    organization.duration = locationArray[4];
    
    // Call placeMarkers method if caller is ProfileViewController
    if ([controller isKindOfClass:[ProfileViewController class]]) {
        [controller placeMarker:organization];
    }
    
    return organization;
}

- (BOOL)beginContentAccess {
    return TRUE;
}

- (void)discardContentIfPossible {
}

- (void)endContentAccess {
}

- (BOOL)isContentDiscarded {
    return FALSE;
}

@end
