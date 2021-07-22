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
@dynamic destinationLatValue;
@dynamic destinationLngValue;
@dynamic distance;
@dynamic distanceValue;

+ (nonnull NSString *)parseClassName {
    return @"Organization";
}


#pragma mark - Initialize Organization object

+ (Organization *)initOrganizationWithObject:(PFObject *)object withLocation:(CLLocation *)userLocation {
    // Parsing location
    NSNumber *userLat = [NSNumber numberWithDouble:userLocation.coordinate.latitude];
    NSNumber *userLng = [NSNumber numberWithDouble:userLocation.coordinate.longitude];
    
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
    
    [Organization getLocationData:userLat withLng:userLng withOrganization:organization];
    
    return organization;
}

+ (void)getLocationData:(NSNumber *)userLat withLng:(NSNumber *)userLng withOrganization:(Organization *)organization {
    [Organization getLocationFromAddress:organization.address withLat:userLat withLng:userLng withOrganization:organization];
    
    // TODO: Fix asynchronous call
    bool flag = TRUE;
    while (flag) {
        if (organization.destinationLatValue != nil) {
            flag = FALSE;
        } else {
            [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]];
        }
    }
}


#pragma mark - Get distance from user location

+ (void)getDistanceFromCoords:(NSNumber *)userLat withLng:(NSNumber *)userLng withOrganization:(Organization *)organization {
    // Getting API Key
    NSString *path = [[NSBundle mainBundle] pathForResource: @"Keys" ofType: @"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
    NSString *apiKey = [dict objectForKey: @"mapsAPIKey"];
    
    // Formatting request
    NSString *requestString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=%@,%@&destinations=%@,%@&key=%@", userLat, userLng, organization.destinationLatValue, organization.destinationLngValue, apiKey];
    
    // API request
    NSURL *url = [NSURL URLWithString:requestString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            NSLog(@"Error: %@", error);
        } else {
            NSDictionary *dataDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            // Calculating distance
            NSString *distance = dataDictionary[@"rows"][0][@"elements"][0][@"distance"][@"text"];
            NSArray *splitDistance = [distance componentsSeparatedByString:@" "];
            NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
            f.numberStyle = NSNumberFormatterDecimalStyle;
            NSNumber *distanceValue = [f numberFromString:[splitDistance objectAtIndex:0]];
            if ([[splitDistance objectAtIndex:1] isEqualToString:@"mi"]) {
                organization.distanceValue = [NSNumber numberWithDouble:[distanceValue doubleValue]];
            } else if ([[splitDistance objectAtIndex:1] isEqualToString:@"ft"]) {
                organization.distanceValue = [NSNumber numberWithDouble:[distanceValue doubleValue]/5280];
            }
            organization.distance = distance;
        }
    }];
    
    [task resume];
}


#pragma mark - Get organization location from address

+ (void)getLocationFromAddress:(NSString *) address withLat:(NSNumber *)userLat withLng:(NSNumber *)userLng withOrganization:(Organization *)organization {
    // Getting API Key
    NSString *path = [[NSBundle mainBundle] pathForResource: @"Keys" ofType: @"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
    NSString *apiKey = [dict objectForKey: @"mapsAPIKey"];
    
    // Getting formatted address string
    NSString *formattedAddress = [address stringByReplacingOccurrencesOfString:@" " withString:@"+" ];
    
    // Formatting request
    NSString *requestString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/geocode/json?address=%@&key=%@", formattedAddress, apiKey];
    
    // API request
    NSURL *url = [NSURL URLWithString:requestString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error != nil) {
            NSLog(@"Error: %@", error);
        } else {
            NSDictionary *dataDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            // Retrieving latitude and longitude
            NSNumber *lat = dataDictionary[@"results"][0][@"geometry"][@"location"][@"lat"];
            NSNumber *lng = dataDictionary[@"results"][0][@"geometry"][@"location"][@"lng"];
            
            // Storing coordinates
            organization.destinationLatValue = lat;
            organization.destinationLngValue = lng;
            
            // Get distance
            [Organization getDistanceFromCoords:userLat withLng:userLng withOrganization:organization];
        }
    }];
    
    [task resume];
}

    
@end
