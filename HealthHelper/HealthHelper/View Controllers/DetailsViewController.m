//
//  DetailsViewController.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/12/21.
//

#import <QuartzCore/QuartzCore.h>
#import "DetailsViewController.h"
#import "OrganizationInfoViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <SDWebImage/SDWebImage.h>
@import GoogleMaps;
@import GooglePlaces;
@import GoogleMapsBase;
@import GoogleMapsCore;
#import "QueryConstants.h"

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
@property (strong, nonatomic) IBOutlet UITapGestureRecognizer *tapGestureRecognizer;

@end

@implementation DetailsViewController 

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Rounded button corners
    self.registerButton.layer.cornerRadius = 10;
    
    // Rounded profile images
    self.profileImageView.layer.cornerRadius = 50;
    
    // Map setup
    self.mapView.myLocationEnabled = true;
    
    // Load basic information from self.opportunity variable
    [self loadBasicProfile];
    
    // Button text
    if ([self.opportunity.opportunityType isEqualToString: @"Donation"]) {
        [self.registerButton setTitle:@"DONATE" forState:UIControlStateNormal];
    } else {
        [self.registerButton setTitle:@"REGISTER" forState:UIControlStateNormal];
    }
    
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
    
    // Setting marker on map
    CLLocationCoordinate2D position = CLLocationCoordinate2DMake([self.opportunity.author.destinationLatValue doubleValue], [self.opportunity.author.destinationLngValue doubleValue]);
    GMSMarker *marker = [GMSMarker markerWithPosition:position];
    marker.title = self.opportunity.author.username;
    marker.map = self.mapView;
    
    // Re-centering map
    self.mapView.camera = [GMSCameraPosition cameraWithLatitude:[self.opportunity.author.destinationLatValue doubleValue] longitude:[self.opportunity.author.destinationLngValue doubleValue] zoom:10];
    
    // Setting distance label
    self.distanceLabel.text = [NSString stringWithFormat:@"Distance: %@", self.opportunity.author.distance];
}

- (IBAction)didTapOrganizationProfile:(id)sender {
    [self performSegueWithIdentifier:@"toOrganizationDetails" sender:nil];
}

- (IBAction)didTapRegister:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString: self.opportunity.signUpLink] options:@{} completionHandler:nil];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Thank you!" message:@"Thanks for checking out this opportunity and making a difference in the community! Did you sign up for this opportunity?" preferredStyle:(UIAlertControllerStyleAlert)];
    UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self registerOpportunity];
    }];
    UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
    [alert addAction:yesAction];
    [alert addAction:noAction];
    [self presentViewController:alert animated:YES completion:^{
    }];
}

- (void)registerOpportunity {
    PFQuery *query = [PFUser query];
    [query includeKey:pastOpportunitiesQuery];
    
    if ([self.opportunity.opportunityType isEqualToString:@"Donation"]) {
        [query includeKey:amountDonatedQuery];
    } else if ([self.opportunity.opportunityType isEqualToString:@"Shadowing"]) {
        [query includeKey:hoursShadowedQuery];
    } else if ([self.opportunity.opportunityType isEqualToString:@"Volunteering"]) {
        [query includeKey:hoursVolunteeredQuery];
    }
    
    [query whereKey:objectIdKey equalTo:PFUser.currentUser.objectId];
    
    // Fetch user asynchronously
    [query findObjectsInBackgroundWithBlock:^(NSArray *users, NSError *error) {
        if (users != nil) {
            // Create and store array of Post objects from retrieved posts
            PFUser *user = users[0];
            
            // Add opportunity id to user's list of opportunities
            NSMutableArray *pastOpportunities = user[pastOpportunitiesQuery];
            
            if (![pastOpportunities containsObject:self.opportunity.opportunityId]) {
                [pastOpportunities addObject:self.opportunity.opportunityId];
                user[pastOpportunitiesQuery] = pastOpportunities;
                
                // Update hours or amount donated
                if ([self.opportunity.opportunityType isEqual:@"Donation"]) {
                    NSNumber *donationAmount = user[amountDonatedQuery];
                    int newAmount = [donationAmount intValue]+[self.opportunity.amount intValue];
                    NSNumber *newDonation = [NSNumber numberWithInt:newAmount];
                    user[amountDonatedQuery] = newDonation;
                    
                } else if ([self.opportunity.opportunityType isEqual:@"Shadowing"]) {
                    NSNumber *hoursShadowed = user[hoursShadowedQuery];
                    int newHours = [hoursShadowed intValue]+[self.opportunity.hours intValue];
                    NSNumber *newHoursShadowed = [NSNumber numberWithInt:newHours];
                    user[hoursShadowedQuery] = newHoursShadowed;
                    
                } else if ([self.opportunity.opportunityType isEqual:@"Volunteering"]) {
                    NSNumber *hoursVolunteered = user[hoursVolunteeredQuery];
                    int newHours = [hoursVolunteered intValue]+[self.opportunity.hours intValue];
                    NSNumber *newHoursVolunteered = [NSNumber numberWithInt:newHours];
                    user[hoursVolunteeredQuery] = newHoursVolunteered;
                    
                }
                
                // Save data
                [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                    if (succeeded) {
                    } else {
                        NSLog(@"Error: %@", error.localizedDescription);
                    }
                }];
            } else {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"You've already signed up!" message:@"You've already signed up for this opportunity, thanks for your contribution!" preferredStyle:(UIAlertControllerStyleAlert)];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
                [alert addAction:okAction];
                [self presentViewController:alert animated:YES completion:^{
                }];
            }
            
        } else {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}

// UIColor from hex color
-(UIColor *)colorWithHex:(UInt32)col {
    unsigned char r, g, b;
    b = col & 0xFF;
    g = (col >> 8) & 0xFF;
    r = (col >> 16) & 0xFF;
    return [UIColor colorWithRed:(float)r/255.0f green:(float)g/255.0f blue:(float)b/255.0f alpha:1];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqual:@"toOrganizationDetails"]) {
        // Sending current opportunity to next view controller
        OrganizationInfoViewController *organizationInfoViewController = [segue destinationViewController];
        organizationInfoViewController.opportunity = self.opportunity;
    }
}

@end
