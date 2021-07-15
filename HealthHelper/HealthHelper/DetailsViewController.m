//
//  DetailsViewController.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/12/21.
//

#import <QuartzCore/QuartzCore.h>
#import "DetailsViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <SDWebImage/SDWebImage.h>
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
@property (weak, nonatomic) IBOutlet UILabel *positionLabel;
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
    
    // Load basic information from self.opportunity variable
    [self loadBasicProfile];
    
    // Get current location
    [self getCurrentLocation];
    
    // Map setup
    self.mapView.myLocationEnabled = true;
}

- (void)viewWillAppear:(BOOL)animated {
    // Loads in user-picked color and dark mode settings
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    bool darkModeStatus = [defaults boolForKey:@"dark_mode_on"];
    int navColor = [defaults integerForKey:@"nav_color"];
    
    // Set bar color
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    navigationBar.barTintColor = [self colorWithHex:navColor];
    self.tabBarController.tabBar.barTintColor = [self colorWithHex:navColor];
    
    // Set dark mode or light mode
    if (darkModeStatus) {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    }
    else {
        self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    }
}

- (void)loadBasicProfile {
    // Set profile image
    [self.profileImageView sd_setImageWithURL:[NSURL URLWithString:self.opportunity.author.imageURL]];
    
    // Set position label
    self.positionLabel.text = [NSString stringWithFormat:@"Position: %@", self.opportunity.position];
    
    // Set description label
    self.descriptionLabel.text = self.opportunity.text;
    
    // Set organization name label
    self.organizationNameLabel.text = self.opportunity.author.username;
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
            NSLog(@"%@", dataDictionary[@"results"][0]);
            NSNumber *lat = dataDictionary[@"results"][0][@"geometry"][@"location"][@"lat"];
            NSNumber *lng = dataDictionary[@"results"][0][@"geometry"][@"location"][@"lng"];
            NSLog(@"%@", lat);
            NSLog(@"%@", lng);
            // Setting marker on map
            CLLocationCoordinate2D position = CLLocationCoordinate2DMake([lat doubleValue], [lng doubleValue]);
            GMSMarker *marker = [GMSMarker markerWithPosition:position];
            marker.title = self.opportunity.author.username;
            marker.map = self.mapView;
            
            // Re-centering map
            self.mapView.camera = [GMSCameraPosition cameraWithLatitude:[lat doubleValue] longitude:[lng doubleValue] zoom:10];
            
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
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    self.latValue = [NSNumber numberWithDouble:location.coordinate.latitude];
    self.lngValue = [NSNumber numberWithDouble:location.coordinate.longitude];
    [locationManager stopUpdatingLocation];
    locationManager = nil;
    
    // Get location from address
    [self getLocationFromAddress:self.opportunity.author.address];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
}

- (IBAction)didTapOrganizationProfile:(id)sender {
    [self performSegueWithIdentifier:@"toOrganizationDetails" sender:nil];
}

// UIColor from hex color
-(UIColor *)colorWithHex:(UInt32)col {
    unsigned char r, g, b;
    b = col & 0xFF;
    g = (col >> 8) & 0xFF;
    r = (col >> 16) & 0xFF;
    return [UIColor colorWithRed:(float)r/255.0f green:(float)g/255.0f blue:(float)b/255.0f alpha:1];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
