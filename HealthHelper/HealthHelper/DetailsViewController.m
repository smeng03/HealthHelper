//
//  DetailsViewController.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/12/21.
//

#import <QuartzCore/QuartzCore.h>
#import "DetailsViewController.h"
#import <CoreLocation/CoreLocation.h>
@import GoogleMaps;
@import GooglePlaces;
@import GoogleMapsBase;
@import GoogleMapsCore;

@interface DetailsViewController () <CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *organizationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *registerButton;
@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (strong, nonatomic) GMSPlacesClient *placesClient;

@end

@implementation DetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Rounded button corners
    self.registerButton.layer.cornerRadius = 10;
    
    // Get current location
    // [self getCurrentLocation];
    
    // Get location from address
    [self getLocationFromAddress:@"1600 Amphitheatre Parkway, Mountain View, CA"];
    
    // Map setup
    self.mapView.myLocationEnabled = true;
}

- (void)getLocationFromAddress:(NSString *) address {
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
            
            // Setting marker on map
            CLLocationCoordinate2D position = CLLocationCoordinate2DMake([lat intValue], [lng intValue]);
            GMSMarker *marker = [GMSMarker markerWithPosition:position];
            marker.title = @"General Hospital";
            marker.map = self.mapView;
            
            // Re-centering map
            self.mapView.camera = [GMSCameraPosition cameraWithLatitude:[lat intValue] longitude:[lng intValue] zoom:10];
        }
    }];
    
    [task resume];
}

/*
- (void)getCurrentLocation {
    // Get current user location
    CLLocationManager *locationManager = [[CLLocationManager alloc] init];
    locationManager.delegate = self;
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
    
    // Placing marker
    CLLocationCoordinate2D position = CLLocationCoordinate2DMake(locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude);
    GMSMarker *marker = [GMSMarker markerWithPosition:position];
    marker.icon = [GMSMarker markerImageWithColor:[UIColor blueColor]];
    marker.title = @"Your Location";
    marker.map = self.mapView;
    
    // Re-centering map
    self.mapView.camera = [GMSCameraPosition cameraWithLatitude:locationManager.location.coordinate.latitude longitude:locationManager.location.coordinate.longitude zoom:10];

    [locationManager stopUpdatingLocation];
}

-(void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLoc
           fromLocation:(CLLocation *)oldLoc
{

    NSLog(@"in locationmanager did update %f",newLoc.coordinate.latitude);
    MKCoordinateRegion region =
    MKCoordinateRegionMakeWithDistance(newLoc.coordinate, 0.01,      0.02);
    [self.mapView setRegion:region animated:YES];
    [self.locationManager stopUpdatingLocation];

}
 */

/*
- (void)locationManager:(CLLocationManager *)manager
    didUpdateToLocation:(CLLocation *)newLocation
           fromLocation:(CLLocation *)oldLocation {
    int degrees = newLocation.coordinate.latitude;
    double decimal = fabs(newLocation.coordinate.latitude - degrees);
    int minutes = decimal * 60;
    double seconds = decimal * 3600 - minutes * 60;
    NSString *lat = [NSString stringWithFormat:@"%d° %d' %1.4f\"",
                     degrees, minutes, seconds];
    NSLog(@" Current Latitude : %@",lat);
    degrees = newLocation.coordinate.longitude;
    decimal = fabs(newLocation.coordinate.longitude - degrees);
    minutes = decimal * 60;
    seconds = decimal * 3600 - minutes * 60;
    NSString *longt = [NSString stringWithFormat:@"%d° %d' %1.4f\"",
                       degrees, minutes, seconds];
    NSLog(@" Current Longitude : %@",longt);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    NSLog(@"OldLocation %f %f", oldLocation.coordinate.latitude, oldLocation.coordinate.longitude);
    NSLog(@"NewLocation %f %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
}
 */

/*
- (void)getCurrentLocation {
    GMSPlaceField fields = (GMSPlaceFieldName | GMSPlaceFieldPlaceID);
    [self.placesClient findPlaceLikelihoodsFromCurrentLocationWithPlaceFields:fields callback:^(NSArray<GMSPlaceLikelihood *> * _Nullable likelihoods, NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"An error occurred %@", [error localizedDescription]);
            return;
        }
        if (likelihoods != nil) {
            for (GMSPlaceLikelihood *likelihood in likelihoods) {
                GMSPlace *place = likelihood.place;
                NSLog(@"Current place name: %@", place.name);
                NSLog(@"Place ID: %@", place.placeID);
            }
        }
        }];
}
 */

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
