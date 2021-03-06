//
//  ProfileViewController.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/12/21.
//

#import <QuartzCore/QuartzCore.h>
#import "ProfileViewController.h"
#import "PastOpportunityCell.h"
#import <Parse/Parse.h>
#import "SceneDelegate.h"
#import "LoginViewController.h"
#import "UIImageView+AFNetworking.h"
#import "MBProgressHUD.h"
#import <SDWebImage/SDWebImage.h>
#import "FBShimmering.h"
#import "FBShimmeringView.h"
#import "FBShimmeringLayer.h"
#import "Opportunity.h"
#import "DetailsViewController.h"
#import "QueryConstants.h"
#import "FilterConstants.h"
#import "Organization.h"
#import "Notification.h"
#import "OrganizationInfoViewController.h"
@import GoogleMaps;
@import GooglePlaces;
@import GoogleMapsBase;
@import GoogleMapsCore;

@interface ProfileViewController () <UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UISearchBarDelegate, CLLocationManagerDelegate, OrganizationDelegate, OpportunityDelegate, PastOpportunityCellDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *hoursVolunteeredLabel;
@property (weak, nonatomic) IBOutlet UILabel *amountDonatedLabel;
@property (weak, nonatomic) IBOutlet UILabel *hoursShadowedLabel;
@property (strong, nonatomic) UIImage *updatedProfileImage;
@property (strong, nonatomic) PFUser *user;
@property (strong, nonatomic) FBShimmeringView *shimmeringView;
@property (strong, nonatomic) NSMutableArray *opportunities;
@property (strong, nonatomic) NSMutableArray *filteredOpportunities;
@property (strong, nonatomic) NSArray *pastOpportunities;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) UIRefreshControl *refreshControl;
@property (strong, nonatomic) CLLocation *userLocation;
@property (strong, nonatomic) NSArray *unprocessedOpportunities;
@property (weak, nonatomic) IBOutlet UIButton *volunteerButton;
@property (weak, nonatomic) IBOutlet UIButton *donateButton;
@property (weak, nonatomic) IBOutlet UIButton *shadowButton;
@property (weak, nonatomic) IBOutlet UIButton *distanceButton;
@property (nonatomic, assign) BOOL volunteerFilterOn;
@property (nonatomic, assign) BOOL shadowFilterOn;
@property (nonatomic, assign) BOOL donateFilterOn;
@property (nonatomic, assign) BOOL distanceFilterOn;
@property (strong, nonatomic) NSMutableArray *filters;
@property (weak, nonatomic) IBOutlet GMSMapView *mapView;
@property (weak, nonatomic) IBOutlet UIView *notificationView;
@property (weak, nonatomic) IBOutlet UILabel *notificationLabel;
@property (strong, nonatomic) GMSCoordinateBounds *bounds;
@property (nonatomic, strong) NSString *units;
@property (nonatomic, strong) NSString *mode;
@property (weak, nonatomic) IBOutlet UIView *mapContainerView;
@property (assign, nonatomic) BOOL firstLoadComplete;

@end

@implementation ProfileViewController

CLLocationManager *locationManager;

#pragma mark - viewDidLoad()

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.firstLoadComplete = FALSE;
    
    // Delegates and data sources
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.searchBar.delegate = self;
    
    // Loading past opportunities
    [self loadPastOpportunityArray];
    
    // Refresh when app comes to foreground
    [[NSNotificationCenter defaultCenter] addObserverForName:@"EnteredForeground" object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self viewWillAppear:TRUE];
    }];
    
    self.units = @"imperial";
    self.mode = @"driving";
    [self styleElements];
    [self filterSetup];
    [self notificationSetup];
    [self.searchBar setBackgroundImage:[UIImage new]];
    
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
    
    // Reload opportunities when needed
    NSString *units = [defaults objectForKey:@"units"];
    NSString *mode = [defaults objectForKey:@"mode"];
    if ([self.units isEqualToString:units] && [self.mode isEqualToString:mode]) {
        
    } else {
        
        [self loadPastOpportunityArray];
        self.units = units;
        self.mode = mode;
        
    }
    
    [self updateDistanceButtonText];
    
}


#pragma mark - Load user's past opportunities

- (void)loadPastOpportunityArray {
    
    // Loading basic profile information
    [self loadBasicProfile];
    
    // Initialize map and location services
    locationManager = [[CLLocationManager alloc] init];
    self.bounds = [[GMSCoordinateBounds alloc] init];
    [self.mapView clear];
    
    // Query for opportunities array
    PFQuery *queryUser = [PFUser query];
    [queryUser includeKey:pastOpportunitiesQuery];
    [queryUser whereKey:objectIdKey equalTo:PFUser.currentUser.objectId];
    
    // Fetch user asynchronously
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [queryUser findObjectsInBackgroundWithBlock:^(NSArray *users, NSError *error) {
            if (users != nil) {
                
                // Create and store array of Post objects from retrieved posts
                PFUser *user = users[0];
                self.pastOpportunities = user[pastOpportunitiesQuery];
                [self loadPastOpportunities];
                
            } else {
                
                NSLog(@"%@", error.localizedDescription);
                
            }
        }];
    });
}

- (void)loadPastOpportunities {
    
    // Construct query for opportunities
    PFQuery *query = [PFQuery queryWithClassName:opportunityClassName];
    [query includeKey:descriptionQuery];
    [query includeKey:tagsQuery];
    [query includeKey:signUpLinkQuery];
    [query includeKey:opportunityTypeQuery];
    [query includeKey:authorQuery];
    [query includeKey:authorImageQuery];
    [query includeKey:authorDescriptionQuery];
    [query includeKey:authorAddressQuery];
    [query includeKey:authorTotalScoreQuery];
    [query includeKey:authorNumReviewsQuery];
    [query includeKey:authorReviewsQuery];
    [query includeKey:opportunityDonationAmountQuery];
    [query includeKey:opportunityHoursQuery];
    [query includeKey:dateQuery];
    [query includeKey:positionQuery];
    [query includeKey:authorPhoneNumberQuery];
    query.limit = 20;
    [query orderByDescending:createdAtQuery];
    [query whereKey:objectIdKey containedIn:self.pastOpportunities];
    
    // Fetch posts asynchronously
    [query findObjectsInBackgroundWithBlock:^(NSArray *opportunities, NSError *error) {
        
        if (opportunities != nil) {
            
            if (opportunities.count > 0) {
                
                self.unprocessedOpportunities = opportunities;
                
                [self getCurrentLocation];
                
            } else {
                
                // No signed up opportunities to display
                self.opportunities = [NSMutableArray new];
                self.filteredOpportunities = self.opportunities;
                
                self.firstLoadComplete = TRUE;
                [self.tableView reloadData];
                [self.refreshControl endRefreshing];
                [self stopAnimation];
                
            }
        } else {
            
            NSLog(@"%@", error.localizedDescription);
            
        }
    }];
}


#pragma mark - Get user location

- (void)getCurrentLocation {
    
    // Get current user location
    locationManager.delegate = self;
    locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [locationManager startUpdatingLocation];
    
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    
    CLLocation *location = [locations lastObject];
    self.userLocation = location;
    self.bounds = [self.bounds includingCoordinate:location.coordinate];
    [locationManager stopUpdatingLocation];
    locationManager = nil;
    
    // Create and store array of Opportunity objects from retrieved posts
    [Opportunity createOpportunityArray:self.unprocessedOpportunities withLocation:self.userLocation withController:self];
    self.filteredOpportunities = self.opportunities;

}

- (void)finishOpportunitySetup:(NSMutableArray *)opportunities {
    
    self.opportunities = opportunities;
    self.filteredOpportunities = self.opportunities;
    
    self.firstLoadComplete = TRUE;
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
    [self stopAnimation];
    
}


#pragma mark - Set map view markers

- (void)placeMarker:(Organization *)organization {
    
    CLLocationCoordinate2D position = CLLocationCoordinate2DMake([organization.destinationLatValue doubleValue], [organization.destinationLngValue doubleValue]);
    GMSMarker *marker = [GMSMarker markerWithPosition:position];
    marker.title = organization.username;
    marker.icon = [GMSMarker markerImageWithColor:[UIColor colorNamed:@"themeColor"]];
    marker.map = self.mapView;
    
    self.bounds = [self.bounds includingCoordinate:marker.position];
    
    // Re-centering map
    GMSCameraUpdate *updateCamera = [GMSCameraUpdate fitBounds:self.bounds withPadding:30];
    [self.mapView moveCamera:updateCamera];
    
}


#pragma mark - Update map markers

- (void)replaceMarkers {
    
    [self.mapView clear];
    
    for (Opportunity *opportunity in self.filteredOpportunities) {
        
        Organization *organization = opportunity.author;
        CLLocationCoordinate2D position = CLLocationCoordinate2DMake([organization.destinationLatValue doubleValue], [organization.destinationLngValue doubleValue]);
        GMSMarker *marker = [GMSMarker markerWithPosition:position];
        marker.title = organization.username;
        marker.icon = [GMSMarker markerImageWithColor:[UIColor colorNamed:@"themeColor"]];
        marker.map = self.mapView;
        
        self.bounds = [self.bounds includingCoordinate:marker.position];
        
        // Re-centering map
        GMSCameraUpdate *updateCamera = [GMSCameraUpdate fitBounds:self.bounds withPadding:30];
        [self.mapView moveCamera:updateCamera];
        
    }
    
}


#pragma mark - Apply filters

-(void)applyFilters:(NSArray *)filteredData {
    
    // Applies all selected filters to a given list of opportunities
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSNumber *maxDistance = [NSNumber numberWithDouble:[defaults doubleForKey:@"maxDistance"]];
    
    for (NSString *filter in self.filters) {
        
        NSPredicate *predicate;
        if ([filter isEqualToString:distanceFilter]) {
            
            predicate = [NSPredicate predicateWithFormat: @"(author.distanceValue <= %@)", maxDistance];
            
        } else {
            
            predicate = [NSPredicate predicateWithFormat: @"(opportunityType CONTAINS[cd] %@)", filter];
            
        }
        
        filteredData = [filteredData filteredArrayUsingPredicate:predicate];
    }
    
    self.filteredOpportunities = [filteredData mutableCopy];
    [self replaceMarkers];
}


#pragma mark - Filter controls

- (IBAction)didTapVolunteerFilter:(id)sender {
    
    // Toggles button color
    if (self.volunteerFilterOn) {
        
        self.volunteerButton.backgroundColor = [UIColor colorWithRed:73/255.0 green:93/255.0 blue:1 alpha:1];
        [self.filters removeObject:volunteeringFilter];
        self.volunteerButton.layer.shadowOpacity = 0.25;
        
    } else {
        
        self.volunteerButton.backgroundColor = [UIColor colorWithRed:0/255.0 green:13/255.0 blue:112/255.0 alpha:1];
        [self.filters addObject:volunteeringFilter];
        self.volunteerButton.layer.shadowOpacity = 0;
        
    }
    
    // Toggles filter on/off state
    self.volunteerFilterOn = !self.volunteerFilterOn;
    
    // Manually trigger search and refilter using updated filters
    [self searchBar:self.searchBar textDidChange: self.searchBar.text];
    
}

- (IBAction)didTapShadowFilter:(id)sender {
    
    // Toggles button color
    if (self.shadowFilterOn) {
        
        self.shadowButton.backgroundColor = [UIColor colorWithRed:73/255.0 green:93/255.0 blue:1 alpha:1];
        [self.filters removeObject:shadowingFilter];
        self.shadowButton.layer.shadowOpacity = 0.25;
        
    } else {
        
        self.shadowButton.backgroundColor = [UIColor colorWithRed:0/255.0 green:13/255.0 blue:112/255.0 alpha:1];
        [self.filters addObject:shadowingFilter];
        self.shadowButton.layer.shadowOpacity = 0;
        
    }
    
    // Toggles filter on/off state
    self.shadowFilterOn = !self.shadowFilterOn;
    
    // Manually trigger search and refilter using updated filters
    [self searchBar:self.searchBar textDidChange: self.searchBar.text];
    
}

- (IBAction)didTapDonateFilter:(id)sender {
    
    // Toggles button color
    if (self.donateFilterOn) {
        
        self.donateButton.backgroundColor = [UIColor colorWithRed:73/255.0 green:93/255.0 blue:1 alpha:1];
        [self.filters removeObject:donationFilter];
        self.donateButton.layer.shadowOpacity = 0.25;
        
    } else {
        
        self.donateButton.backgroundColor = [UIColor colorWithRed:0/255.0 green:13/255.0 blue:112/255.0 alpha:1];
        [self.filters addObject:donationFilter];
        self.donateButton.layer.shadowOpacity = 0;
        
    }
    
    // Toggles filter on/off state
    self.donateFilterOn = !self.donateFilterOn;
    
    // Manually trigger search and refilter using updated filters
    [self searchBar:self.searchBar textDidChange: self.searchBar.text];
    
}

- (IBAction)didTapDistanceFilter:(id)sender {
    
    // Toggles button color
    if (self.distanceFilterOn) {
        
        self.distanceButton.backgroundColor = [UIColor colorWithRed:73/255.0 green:93/255.0 blue:1 alpha:1];
        [self.filters removeObject:distanceFilter];
        self.distanceButton.layer.shadowOpacity = 0.25;
        
    } else {
        
        self.distanceButton.backgroundColor = [UIColor colorWithRed:0/255.0 green:13/255.0 blue:112/255.0 alpha:1];
        [self.filters addObject:distanceFilter];
        self.distanceButton.layer.shadowOpacity = 0;
        
    }
    
    // Toggles filter on/off state
    self.distanceFilterOn = !self.distanceFilterOn;
    
    // Manually trigger search and refilter using updated filters
    [self searchBar:self.searchBar textDidChange: self.searchBar.text];
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    NSLog(@"didFailWithError: %@", error);
}


#pragma mark - Load basic profile information

- (void)loadBasicProfile {
    
    // Setting username
    self.usernameLabel.text = PFUser.currentUser.username;
    
    // Querying for profile image
    PFQuery *query = [PFUser query];
    [query includeKey:imageQuery];
    [query includeKey:amountDonatedQuery];
    [query includeKey:hoursVolunteeredQuery];
    [query includeKey:hoursShadowedQuery];
    [query whereKey:objectIdKey equalTo:PFUser.currentUser.objectId];
    
    // Fetch user asynchronously
    [query findObjectsInBackgroundWithBlock:^(NSArray *users, NSError *error) {
        if (users != nil) {
            
            // Create and store array of Post objects from retrieved posts
            PFUser *user = users[0];
            
            // Set profile image
            PFFileObject *image = user[imageQuery];
            [self.profileImageView sd_setImageWithURL:[NSURL URLWithString:image.url]];
            self.shimmeringView.shimmering = NO;
            
            // Set user sats
            self.hoursVolunteeredLabel.text = [NSString stringWithFormat:@"Hours volunteered: %@", user[hoursVolunteeredQuery]];
            self.amountDonatedLabel.text = [NSString stringWithFormat:@"Amount donated: $%@", user[amountDonatedQuery]];
            self.hoursShadowedLabel.text = [NSString stringWithFormat:@"Hours shadowed: %@", user[hoursShadowedQuery]];
            
        } else {
            
            NSLog(@"%@", error.localizedDescription);
            
        }
    }];
}


#pragma mark - Table View

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    PastOpportunityCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"PastOpportunityCell"];
    
    // Setting cell and style
    [cell setCell:self.filteredOpportunities[indexPath.row] withDelegate:self];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
    
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    if (self.filteredOpportunities.count == 0) {
        
        if (self.firstLoadComplete) {
            
            [self setEmptyMessage];
            
        }
        
    } else {
        
        [self clearEmptyMessage];
        
    }
    
    return self.filteredOpportunities.count;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {

    // remove bottom extra 20px space
    return CGFLOAT_MIN;
}

- (void)setEmptyMessage {
    
    // Table view empty message
    UILabel *noDataLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.tableView.bounds.size.height)];
    noDataLabel.text = @"No opportunities to display";
    noDataLabel.textColor = [UIColor grayColor];
    noDataLabel.textAlignment = NSTextAlignmentCenter;
    self.tableView.backgroundView = noDataLabel;
    
}

- (void)clearEmptyMessage {
    
    // Table view clear message
    self.tableView.backgroundView = nil;
    
}


#pragma mark - Logout

- (IBAction)didTapLogout:(id)sender {
    
    [PFUser logOutInBackgroundWithBlock:^(NSError * _Nullable error) {
        // PFUser.current() will now be nil
    }];
    
    // Showing login screen after logout
    SceneDelegate *myDelegate = (SceneDelegate *)self.view.window.windowScene.delegate;
    
    // Logging out and swtiching to login view controller
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LoginViewController *loginViewController = [storyboard instantiateViewControllerWithIdentifier:@"LoginViewController"];
    myDelegate.window.rootViewController = loginViewController;
    
}


#pragma mark - Delete an opportunity

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        // Making sure user does want to delete opportunity
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Deleting opportunity" message:@"Are you sure you want to delete this opportunity from your records? This action is permanent and cannot be undone." preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            // Getting opportunity user tapped on
            Opportunity *opportunity = self.filteredOpportunities[indexPath.row];
            
            // Constructing query to delete opportunity
            PFQuery *query = [PFUser query];
            [query includeKey:pastOpportunitiesQuery];
            [query includeKey:tagsQuery];
            
            if ([opportunity.opportunityType isEqualToString:donationOpportunityType]) {
                
                [query includeKey:amountDonatedQuery];
                
            } else if ([opportunity.opportunityType isEqualToString:shadowingOpportunityType]) {
                
                [query includeKey:hoursShadowedQuery];
                
            } else if ([opportunity.opportunityType isEqualToString:volunteeringOpportunityType]) {
                
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
                    
                    // Remove associated tags
                    NSMutableDictionary *userTags = user[tagsQuery];
                    for (NSString *tag in opportunity.tags) {
                        NSNumber *tagValue = userTags[tag];
                        if ([tagValue intValue] <= 1) {
                            [userTags removeObjectForKey:tag];
                        } else {
                            userTags[tag] = [NSNumber numberWithInt:[tagValue intValue] - 1];
                        }
                    }
                    user[tagsQuery] = userTags;
                    
                    // Removing opportunity user deleted
                    [pastOpportunities removeObject:opportunity.opportunityId];
                    user[pastOpportunitiesQuery] = pastOpportunities;
                    
                    // Update hours or amount donated
                    if ([opportunity.opportunityType isEqual:donationOpportunityType]) {
                        
                        NSNumber *donationAmount = user[amountDonatedQuery];
                        int newAmount = [donationAmount intValue]-[opportunity.amount intValue];
                        NSNumber *newDonation = [NSNumber numberWithInt:newAmount];
                        user[amountDonatedQuery] = newDonation;
                        
                    } else if ([opportunity.opportunityType isEqual:shadowingOpportunityType]) {
                        
                        NSNumber *hoursShadowed = user[hoursShadowedQuery];
                        int newHours = [hoursShadowed intValue]-[opportunity.hours intValue];
                        NSNumber *newHoursShadowed = [NSNumber numberWithInt:newHours];
                        user[hoursShadowedQuery] = newHoursShadowed;
                        
                    } else if ([opportunity.opportunityType isEqual:volunteeringOpportunityType]) {
                        
                        NSNumber *hoursVolunteered = user[hoursVolunteeredQuery];
                        int newHours = [hoursVolunteered intValue]-[opportunity.hours intValue];
                        NSNumber *newHoursVolunteered = [NSNumber numberWithInt:newHours];
                        user[hoursVolunteeredQuery] = newHoursVolunteered;
                        
                    }
                    
                    // Save data
                    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                        
                        if (succeeded) {
                            
                            // Reload user interface
                            [self.filteredOpportunities removeObjectAtIndex:indexPath.row];
                            [tableView reloadData];
                            [self loadPastOpportunityArray];
                            
                        } else {
                            
                            NSLog(@"Error: %@", error.localizedDescription);
                            
                        }
                    }];

                } else {
                    
                    NSLog(@"%@", error.localizedDescription);
                    
                }
            }];
        }];
        
        UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
        [alert addAction:yesAction];
        [alert addAction:noAction];
        [self presentViewController:alert animated:YES completion:^{}];
        
    }
}


#pragma mark - Pick and save new profile image

- (IBAction)didTapProfilePicture:(id)sender {
    
    // Setting up image picker controller
    UIImagePickerController *imagePickerVC = [UIImagePickerController new];
    imagePickerVC.delegate = self;
    imagePickerVC.allowsEditing = YES;
    
    // If user has a camera, they can choose between camera roll or camera
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        
        // Choose between picking a picture or using camera
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Open camera or camera roll?" message:@"Do you want to choose a photo from your camera roll or take a new picture?" preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *cameraRollAction = [UIAlertAction actionWithTitle:@"Open camera roll" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            imagePickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            // Present image picker controller
            [self presentViewController:imagePickerVC animated:YES completion:nil];
        }];
        UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"Take a photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            imagePickerVC.sourceType = UIImagePickerControllerSourceTypeCamera;
            // Present image picker controller
            [self presentViewController:imagePickerVC animated:YES completion:nil];
        }];
        [alert addAction:cameraRollAction];
        [alert addAction:cameraAction];
        [self presentViewController:alert animated:YES completion:^{}];
        
    } else {
        
        // If user does not have camera, they can only chooe from camera roll
        imagePickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        // Present image picker controller
        [self presentViewController:imagePickerVC animated:YES completion:nil];
        
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    // Get the image captured by the UIImagePickerController and store it
    UIImage *editedImage = info[UIImagePickerControllerEditedImage];
    CGSize imageSize = CGSizeMake(300, 300);
    UIImage *resizedImage = [self resizeImage:editedImage withSize:imageSize];
    self.updatedProfileImage = resizedImage;
    [self saveImage];
    
    // Dismiss UIImagePickerController to go back to your original view controller
    [self dismissViewControllerAnimated:YES completion:nil];
    
}

- (void)saveImage {
    
    // Save image to current user object
    PFUser *user = PFUser.currentUser;
    NSData *imageData = UIImagePNGRepresentation(self.updatedProfileImage);
    user[imageQuery] = [PFFileObject fileObjectWithName:@"image.png" data:imageData contentType:@"image/png"];
    
    // Progress HUD while post is saved
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        
        // Update image in database
        [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
            if (succeeded) {
                
                // Display new profile image
                self.profileImageView.image = self.updatedProfileImage;
                
            } else {
                
                // Otherwise, displays an alert
                NSLog(@"Problem saving image: %@", error.localizedDescription);
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Error posting image." preferredStyle:(UIAlertControllerStyleAlert)];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
                [alert addAction:okAction];
                [self presentViewController:alert animated:YES completion:^{}];
                
            }
            
            [self stopAnimation];
            
        }];
    });
}


#pragma mark - Search Bar

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    if (searchText.length != 0) {
        
        // Searches for objects containing what the user types
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *searchBy = [defaults objectForKey:@"searchBy"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(%@ CONTAINS[cd] %@)", searchBy, searchText];
        
        // Filters opportunities based on search criteria
        NSArray *filteredData = [self.opportunities filteredArrayUsingPredicate:predicate];
        
        // Apply additional filters to the opportunities filtered from search
        [self applyFilters:filteredData];
        
    }
    else {
        
        // Apply additional filters to full list of opportunities if no search criteria
        [self applyFilters:self.opportunities];
        
    }
    
    // Refresh table view
    [self.tableView reloadData];
    
}

// Search bar cancel button shows
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    
    self.searchBar.showsCancelButton = YES;
    
}

// Search bar and cancel button disappear when button clicked
- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    
    self.searchBar.showsCancelButton = NO;
    [self.searchBar resignFirstResponder];
    
}


#pragma mark - Setup styling

- (void)styleElements {
    
    // Round profile images
    self.profileImageView.layer.cornerRadius = 50;
    
    // Search bar placeholder text
    self.searchBar.placeholder = @"Search your opportunities...";
    
    [self styleButton];
    
    // Map view styling
    self.mapView.layer.cornerRadius = 10;
    self.mapContainerView.layer.cornerRadius = 10;
    self.mapContainerView.layer.shadowOffset = CGSizeMake(0, 0);
    self.mapContainerView.layer.shadowRadius = 3;
    self.mapContainerView.layer.shadowOpacity = 0.25;
    
    // Map user location enabled
    self.mapView.myLocationEnabled = true;
    
    // Refresh Control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(loadPastOpportunityArray) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:self.refreshControl atIndex:0];
    
    // Placeholder shimmer while loading
    self.shimmeringView = [[FBShimmeringView alloc] initWithFrame:self.profileImageView.frame];
    self.shimmeringView.contentView = self.profileImageView;
    [self.view addSubview:self.shimmeringView];
    self.shimmeringView.shimmering = YES;

}

- (void)filterSetup {
    
    // Initialize filter values
    self.volunteerFilterOn = FALSE;
    self.shadowFilterOn = FALSE;
    self.donateFilterOn = FALSE;
    self.distanceFilterOn = FALSE;
    
    // Initialize filters array
    self.filters = [NSMutableArray new];
    
}

- (void)styleButton {
    
    // Buttons have rounded corners
    self.volunteerButton.layer.cornerRadius = 20;
    self.shadowButton.layer.cornerRadius = 20;
    self.donateButton.layer.cornerRadius = 20;
    self.distanceButton.layer.cornerRadius = 20;
    
    // Button colors
    self.volunteerButton.backgroundColor = [UIColor colorWithRed:73/255.0 green:93/255.0 blue:1 alpha:1];
    self.shadowButton.backgroundColor = [UIColor colorWithRed:73/255.0 green:93/255.0 blue:1 alpha:1];
    self.donateButton.backgroundColor = [UIColor colorWithRed:73/255.0 green:93/255.0 blue:1 alpha:1];
    self.distanceButton.backgroundColor = [UIColor colorWithRed:73/255.0 green:93/255.0 blue:1 alpha:1];
    
    // Button shadows
    self.volunteerButton.layer.shadowOffset = CGSizeMake(0, 0);
    self.volunteerButton.layer.shadowRadius = 3;
    self.volunteerButton.layer.shadowOpacity = 0.4;
    
    self.shadowButton.layer.shadowOffset = CGSizeMake(0, 0);
    self.shadowButton.layer.shadowRadius = 3;
    self.shadowButton.layer.shadowOpacity = 0.4;
    
    self.donateButton.layer.shadowOffset = CGSizeMake(0, 0);
    self.donateButton.layer.shadowRadius = 3;
    self.donateButton.layer.shadowOpacity = 0.4;
    
    self.distanceButton.layer.shadowOffset = CGSizeMake(0, 0);
    self.distanceButton.layer.shadowRadius = 3;
    self.distanceButton.layer.shadowOpacity = 0.4;
    
    [self updateDistanceButtonText];
    
}

- (void)updateDistanceButtonText {
    
    // Distance button text
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *units;
    if ([self.units isEqualToString:@"imperial"]) {
        units = @"mi";
    } else {
        units = @"km";
    }
    
    [self.distanceButton setTitle:[NSString stringWithFormat:@"??? %@ %@", [NSNumber numberWithDouble:[defaults doubleForKey:@"maxDistance"]], units] forState:UIControlStateNormal];
    
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


#pragma mark - Other functions

- (void)stopAnimation {
    
    // Stopping progress HUD
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });
    
}


#pragma mark - Resize image

- (UIImage *)resizeImage:(UIImage *)image withSize:(CGSize)size {
    
    // Resizes an image to a specified size
    UIImageView *resizeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    
    resizeImageView.contentMode = UIViewContentModeScaleAspectFill;
    resizeImageView.image = image;
    
    UIGraphicsBeginImageContext(size);
    [resizeImageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
    
}


#pragma mark - Segue to organization details

- (void)didTapOrganizationProfile:(Opportunity *)opportunity {
    
    [self performSegueWithIdentifier:@"toOrganizationDetails3" sender:opportunity];
    
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    // Segue for details view controller
    if ([segue.identifier isEqualToString:@"toDetails"]) {
        
        // Identify tapped cell and get associated opportunity
        UITableViewCell *tappedCell = sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:tappedCell];
        Opportunity *opportunity = self.filteredOpportunities[indexPath.row];
        
        // Send information
        DetailsViewController *detailsViewController = [segue destinationViewController];
        detailsViewController.opportunity = opportunity;
        detailsViewController.userLocation = self.userLocation;
        
    } else if ([segue.identifier isEqualToString:@"toOrganizationDetails3"]) {
        
        OrganizationInfoViewController *organizationInfoViewController = [segue destinationViewController];
        organizationInfoViewController.opportunity = sender;
        
    }
}

@end
