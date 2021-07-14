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
@property (strong, nonatomic) NSNumber *latValue;
@property (strong, nonatomic) NSNumber *lngValue;
@property (strong, nonatomic) NSNumber *destinationLatValue;
@property (strong, nonatomic) NSNumber *destinationLngValue;

@end

@implementation DetailsViewController 

CLLocationManager *locationManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    locationManager = [[CLLocationManager alloc] init];
    
    // Rounded button corners
    self.registerButton.layer.cornerRadius = 10;
    
    // Rounded profile images
    self.profileImageView.layer.cornerRadius = 50;
    
    // Get current location
    [self getCurrentLocation];
    
    // Map setup
    self.mapView.myLocationEnabled = true;
}

- (void)viewWillAppear:(BOOL)animated {
    // Loads in user-picked color and dark mode settings
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    bool darkModeStatus = [defaults boolForKey:@"dark_mode_on"];
    
    // Set dark mode or light mode
    if (darkModeStatus) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    }
    else {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
}

- (void)getDistanceFromCoords {
    // Getting API Key
    NSString *path = [[NSBundle mainBundle] pathForResource: @"Keys" ofType: @"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
    NSString *apiKey = [dict objectForKey: @"mapsAPIKey"];
    
    // Formatting request
    NSString *requestString = [NSString stringWithFormat:@"https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=%@,%@&destinations=%@,%@&key=%@", self.latValue, self.lngValue, self.destinationLatValue, self.destinationLngValue, apiKey];
    NSLog(@"%@", requestString);
    
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
            NSString *distance = dataDictionary[@"rows"][0][@"elements"][0][@"distance"][@"text"];
            
            // Setting distance label
            self.distanceLabel.text = distance;
        }
    }];
    
    [task resume];
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
            
            // Storing coordinates
            self.destinationLatValue = lat;
            self.destinationLngValue = lng;
            
            // Get distance
            [self getDistanceFromCoords];
        }
    }];
    
    [task resume];
}


- (void)getCurrentLocation {
    // Get current user location
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    
    [locationManager startUpdatingLocation];
    
    /*// Placing marker
    CLLocationCoordinate2D position = CLLocationCoordinate2DMake(locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude);
    GMSMarker *marker = [GMSMarker markerWithPosition:position];
    marker.icon = [GMSMarker markerImageWithColor:[UIColor blueColor]];
    marker.title = @"Your Location";
    marker.map = self.mapView;
    
    // Re-centering map
    self.mapView.camera = [GMSCameraPosition cameraWithLatitude:locationManager.location.coordinate.latitude longitude:locationManager.location.coordinate.longitude zoom:10];
    */
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    self.latValue = [NSNumber numberWithDouble:location.coordinate.latitude];
    self.lngValue = [NSNumber numberWithDouble:location.coordinate.longitude];
    [locationManager stopUpdatingLocation];
    locationManager = nil;
    
    // Get location from address
    [self getLocationFromAddress:@"1600 Amphitheatre Parkway, Mountain View, CA"];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
}


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
*/

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    NSLog(@"OldLocation %f %f", oldLocation.coordinate.latitude, oldLocation.coordinate.longitude);
    NSLog(@"NewLocation %f %f", newLocation.coordinate.latitude, newLocation.coordinate.longitude);
}
 

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
