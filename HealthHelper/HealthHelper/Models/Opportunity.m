//
//  Opportunity.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/14/21.
//

#import <Foundation/Foundation.h>
#import "Opportunity.h"
#import "Organization.h"
#import <CoreLocation/CoreLocation.h>

@interface Opportunity() <NSDiscardableContent>

@end

@implementation Opportunity 

NSMutableArray *newOpportunities = nil;

@dynamic opportunityId;
@dynamic timeCreatedAt;
@dynamic timeUpdatedAt;
@dynamic author;
@dynamic text;
@dynamic tags;
@dynamic signUpLink;
@dynamic opportunityType;
@dynamic position;
@dynamic date;
@dynamic hours;
@dynamic amount;
@dynamic delegate;

+ (nonnull NSString *)parseClassName {
    return @"Opportunity";
}

- (void)initOpportunityWithObject:(PFObject *)object withLocationArray:(NSArray *)locationsList withController:controller {
    
    // Setting Opportunity object given PFObject
    self.text = object[@"description"];
    self.tags = object[@"tags"];
    self.signUpLink = object[@"signUpLink"];
    self.opportunityType = object[@"opportunityType"];
    self.position = object[@"position"];
    self.opportunityId = object.objectId;
    self.timeCreatedAt = object.createdAt;
    self.timeUpdatedAt = object.updatedAt;
    self.date = object[@"date"];
    self.hours = object[@"hours"];
    self.amount = object[@"donationAmount"];
    self.author = [Organization initOrganizationWithObject:object[@"author"] withLocationArray:locationsList withController:controller];
    
}

+ (void)createOpportunityArray:(NSArray *)objects withLocation:(CLLocation *)userLocation withController:controller {
    
    // New array to store locations and default value
    NSMutableArray *locationsList = [NSMutableArray new];
    for (int i=0; i < objects.count; i++) {
        [locationsList addObject:@[[NSNumber numberWithInt:0], [NSNumber numberWithInt:0]]];
    }
    [Opportunity getLocationsFromAddress:objects withLocations:locationsList withUserLocation:userLocation withController:controller];
    
}

+ (void)getLocationsFromAddress:(NSArray *)objects withLocations:(NSMutableArray *)locationsList withUserLocation:(CLLocation *)userLocation withController:controller {
    
    __block int numCompletedRequests = 0;
    
    for (int j=0; j<objects.count; j++) {
        PFObject *object = objects[j];
        
        // Getting API Key
        NSString *path = [[NSBundle mainBundle] pathForResource: @"Keys" ofType: @"plist"];
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
        NSString *apiKey = [dict objectForKey: @"mapsAPIKey"];
        
        // Getting formatted address string
        NSString *formattedAddress = [object[@"author"][@"address"] stringByReplacingOccurrencesOfString:@" " withString:@"+" ];
        
        // Formatting request
        NSString *requestString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/geocode/json?address=%@&key=%@", formattedAddress, apiKey];
        
        // API request
        NSURL *url = [NSURL URLWithString:requestString];
        NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            if (error != nil) {
                
                // Logging request as completed
                numCompletedRequests++;
                NSLog(@"Error: %@", error);
                
            } else {
                
                NSDictionary *dataDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                
                // Retrieving latitude and longitude
                NSNumber *lat = dataDictionary[@"results"][0][@"geometry"][@"location"][@"lat"];
                NSNumber *lng = dataDictionary[@"results"][0][@"geometry"][@"location"][@"lng"];
                
                // Storing coordinates
                [locationsList replaceObjectAtIndex:j withObject:@[lat, lng]];
                
                // Logging request as completed
                numCompletedRequests++;
                
                // Get distance
                if (numCompletedRequests == objects.count) {
                    [Opportunity getDistanceFromCoords:userLocation withObjects:objects withLocations:locationsList withController:controller];
                }
            }
        }];
        
        [task resume];
    }
}

+ (void)getDistanceFromCoords:(CLLocation *)userLocation withObjects:(NSArray *)objects withLocations:(NSMutableArray *)locationsList withController:controller {
    
    newOpportunities = [NSMutableArray new];
    
    // Getting user travel preferences
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *units = [defaults objectForKey:@"units"];
    NSString *mode = [defaults objectForKey:@"mode"];
    
    // Parsing location
    NSNumber *userLat = [NSNumber numberWithDouble:userLocation.coordinate.latitude];
    NSNumber *userLng = [NSNumber numberWithDouble:userLocation.coordinate.longitude];
    
    // Getting API Key
    NSString *path = [[NSBundle mainBundle] pathForResource: @"Keys" ofType: @"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
    NSString *apiKey = [dict objectForKey: @"mapsAPIKey"];
    
    // Formatting request
    NSString *requestString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/distancematrix/json?mode=%@&units=%@&origins=%@,%@&destinations=%@%%2C%@", mode, units, userLat, userLng, locationsList[0][0], locationsList[0][1]];
    
    int i;
    for (i=1; i<locationsList.count; i++) {
        requestString = [NSString stringWithFormat:@"%@%%7C%@%%2C%@", requestString, locationsList[i][0], locationsList[i][1]];
    }
    requestString = [NSString stringWithFormat:@"%@&key=%@", requestString, apiKey];
    
    // API request
    NSURL *url = [NSURL URLWithString:requestString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:10.0];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error != nil) {
            
            NSLog(@"Error: %@", error);
            
        } else {
            
            NSDictionary *dataDictionary = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
            
            // Calculating distances, initializing Organization objects
            int i;
            for (i=0; i<objects.count; i++) {
                
                // Finding correct address and location
                NSArray *addresses = dataDictionary[@"destination_addresses"];
                NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(SELF CONTAINS[cd] %@)", objects[i][@"author"][@"address"]];
                NSArray *filteredAddresses = [addresses filteredArrayUsingPredicate:predicate];
                NSUInteger index = [addresses indexOfObject:filteredAddresses[0]];
                
                // Finding distance
                NSString *distance = dataDictionary[@"rows"][0][@"elements"][index][@"distance"][@"text"];
                NSString *duration = dataDictionary[@"rows"][0][@"elements"][index][@"duration"][@"text"];
                NSArray *splitDistance = [distance componentsSeparatedByString:@" "];
                NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
                f.numberStyle = NSNumberFormatterDecimalStyle;
                NSNumber *distanceValue = [f numberFromString:[splitDistance objectAtIndex:0]];
                
                // Normalizing distance and creating new Opportunity
                Opportunity *newOpportunity = [Opportunity new];
                
                if ([[splitDistance objectAtIndex:1] isEqualToString:@"mi"]) {
    
                    [newOpportunity initOpportunityWithObject:objects[i] withLocationArray:@[locationsList[i][0], locationsList[i][1], distance, [NSNumber numberWithDouble:[distanceValue doubleValue]], duration] withController:controller];
                    
                } else if ([[splitDistance objectAtIndex:1] isEqualToString:@"ft"]) {
                    
                    [newOpportunity initOpportunityWithObject:objects[i] withLocationArray:@[locationsList[i][0], locationsList[i][1], distance, [NSNumber numberWithDouble:[distanceValue doubleValue]/5280], duration] withController:controller];
                    
                } else if ([[splitDistance objectAtIndex:1] isEqualToString:@"km"]) {
                    
                    [newOpportunity initOpportunityWithObject:objects[i] withLocationArray:@[locationsList[i][0], locationsList[i][1], distance, [NSNumber numberWithDouble:[distanceValue doubleValue]], duration] withController:controller];
                    
                } else if ([[splitDistance objectAtIndex:1] isEqualToString:@"m"]) {
                    
                    [newOpportunity initOpportunityWithObject:objects[i] withLocationArray:@[locationsList[i][0], locationsList[i][1], distance, [NSNumber numberWithDouble:[distanceValue doubleValue]/1000], duration] withController:controller];
                    
                }
                
                [newOpportunities addObject:newOpportunity];
            }
            
            // Pass opportunities back to view controller
            [controller finishOpportunitySetup:newOpportunities];
        }
    }];
    
    [task resume];
}

    
- (BOOL)beginContentAccess {
    
    return TRUE;
    
}

- (BOOL)isContentDiscarded {
    
    return FALSE;
    
}

- (void)discardContentIfPossible {
    
}

- (void)endContentAccess {
    
}

@end




