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
#import "GMYConfettiView.h"
#import "Notification.h"

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
@property (nonatomic, strong) GMYConfettiView *confettiView;
@property (weak, nonatomic) IBOutlet UIView *notificationView;
@property (weak, nonatomic) IBOutlet UILabel *notificationLabel;
@property (strong, nonatomic) GMSCoordinateBounds *bounds;

@end

@implementation DetailsViewController

#pragma mark - viewDidLoad()

- (void)viewDidLoad {
    
    [super viewDidLoad];

    // Map setup
    self.mapView.myLocationEnabled = true;
    self.bounds = [[GMSCoordinateBounds alloc] init];
    
    // Load basic information from self.opportunity variable
    [self loadBasicProfile];
    [self styleElements];
    [self notificationSetup];
    
}


#pragma mark - viewWillAppear()

- (void)viewWillAppear:(BOOL)animated {
    
    // Loads in user-picked color
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *navColor = [defaults objectForKey:@"nav_color"];
    
    // Set bar color
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    navigationBar.barTintColor = [UIColor colorNamed:navColor];
    self.tabBarController.tabBar.barTintColor = [UIColor colorNamed:navColor];
    
}


#pragma mark - Load basic profile information

- (void)loadBasicProfile {
    
    // Set profile image
    self.profileImageView.alpha = 0;
    [self.profileImageView sd_setImageWithURL:[NSURL URLWithString:self.opportunity.author.imageURL] placeholderImage:nil options:SDWebImageRetryFailed completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (image) {
            BOOL animated = NO;

            if (cacheType == SDImageCacheTypeDisk || cacheType == SDImageCacheTypeNone) {
                animated = YES;
            }

            self.profileImageView.image = image;

            if (animated) {
                [UIView animateWithDuration:1 animations:^{
                    self.profileImageView.alpha = 1.0;
                }];

            } else {
                self.profileImageView.alpha = 1.0;
            }
        }
    }];
    
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
    marker.icon = [GMSMarker markerImageWithColor:[UIColor colorNamed:@"themeColor"]];
    marker.map = self.mapView;
    
    // Re-centering map
    self.bounds = [self.bounds includingCoordinate:marker.position];
    self.bounds = [self.bounds includingCoordinate:self.userLocation.coordinate];
    GMSCameraUpdate *updateCamera = [GMSCameraUpdate fitBounds:self.bounds withPadding:30];
    [self.mapView moveCamera:updateCamera];
    
    // Setting distance label
    self.distanceLabel.text = [NSString stringWithFormat:@"Distance: %@", self.opportunity.author.distance];
    
}

- (IBAction)didTapOrganizationProfile:(id)sender {
    
    [self performSegueWithIdentifier:@"toOrganizationDetails" sender:nil];
    
}


#pragma mark - Register for an opportunity

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
    [query includeKey:tagsQuery];
    
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
            
            // Add opportunity tags to user
            // NSMutableArray *userTags = user[tagsQuery];
            // [userTags addObjectsFromArray:self.opportunity.tags];
            // user[tagsQuery] = userTags;
            
            NSMutableDictionary *userTags = user[tagsQuery];
            for (NSString *tag in self.opportunity.tags) {
                if ([userTags objectForKey:tag]) {
                    NSNumber *tagValue = userTags[tag];
                    userTags[tag] = [NSNumber numberWithInt:[tagValue intValue] + 1];
                } else {
                    userTags[tag] = [NSNumber numberWithInt:1];
                }
            }
            user[tagsQuery] = userTags;
            
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
                        
                        // Initializing a confetti view to display confetti
                        self.confettiView = [[GMYConfettiView alloc] initWithFrame:self.view.bounds];
                        [self.view addSubview:self.confettiView];
                        [self.confettiView startConfetti];
                        
                        // Play confetti for 3 seconds
                        [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(stopConfetti) userInfo:nil repeats:NO];
                        
                    } else {
                        
                        NSLog(@"Error: %@", error.localizedDescription);
                        
                    }
                }];
                
            } else {
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"You've already signed up!" message:@"You've already signed up for this opportunity, thanks for your contribution!" preferredStyle:(UIAlertControllerStyleAlert)];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
                [alert addAction:okAction];
                [self presentViewController:alert animated:YES completion:^{}];
                
            }
            
        } else {
            
            NSLog(@"%@", error.localizedDescription);
            
        }
    }];
}


#pragma mark - Notification setup

- (void)notificationSetup {
    
    // Hide notification view
    [self.notificationView setHidden:YES];
    
    // Success notification
    [[NSNotificationCenter defaultCenter] addObserverForName:@"ReviewPosted" object:nil queue:nil usingBlock:^(NSNotification *note) {
        [Notification successNotificationAction:self.notificationView withLabel:self.notificationLabel];
        [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(hideNotification) userInfo:nil repeats:NO];
    }];
    
    
    // Failure notification
    [[NSNotificationCenter defaultCenter] addObserverForName:@"ReviewFailed" object:nil queue:nil usingBlock:^(NSNotification *note) {
        [Notification failureNotificationAction:self.notificationView withLabel:self.notificationLabel];
        [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(hideNotification) userInfo:nil repeats:NO];
    }];
    
}


#pragma mark - Hide notification

- (void)hideNotification {
    
    [Notification hideNotificationAction:self.notificationView];
}


#pragma mark - Stop confetti

- (void)stopConfetti {
    
    [self.confettiView stopConfetti];
    self.confettiView = nil;
    
}


#pragma mark - Setup styling

- (void)styleElements {
    
    // Rounded button corners
    self.registerButton.layer.cornerRadius = 10;
    
    // Rounded profile images
    self.profileImageView.layer.cornerRadius = 50;
    
    // Button text
    if ([self.opportunity.opportunityType isEqualToString: @"Donation"]) {
        [self.registerButton setTitle:@"DONATE" forState:UIControlStateNormal];
    } else {
        [self.registerButton setTitle:@"REGISTER" forState:UIControlStateNormal];
    }
    
    // Map corner radius
    self.mapView.layer.cornerRadius = 10;
    
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqual:@"toOrganizationDetails"]) {
        
        // Sending current opportunity to next view controller
        OrganizationInfoViewController *organizationInfoViewController = [segue destinationViewController];
        organizationInfoViewController.opportunity = self.opportunity;
        
    }
    
}

@end
