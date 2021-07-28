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
@import GoogleMaps;
@import GooglePlaces;
@import GoogleMapsBase;
@import GoogleMapsCore;

@interface ProfileViewController () <UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UISearchBarDelegate, CLLocationManagerDelegate, OrganizationDelegate, OpportunityDelegate>

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

@end

@implementation ProfileViewController

CLLocationManager *locationManager;

#pragma mark - viewDidLoad()

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Delegates and data sources
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.searchBar.delegate = self;
    
    // Loading basic profile information
    [self loadBasicProfile];
    
    // Loading past opportunities
    [self loadPastOpportunityArray];
    
    // Refresh Control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(loadPastOpportunityArray) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:self.refreshControl atIndex:0];
    
    // Placeholder shimmer while loading
    // self.profileImageView.image = [SDAnimatedImage imageNamed:@"loading_square.gif"];
    self.shimmeringView = [[FBShimmeringView alloc] initWithFrame:self.profileImageView.frame];
    self.shimmeringView.contentView = self.profileImageView;
    [self.view addSubview:self.shimmeringView];
    self.shimmeringView.shimmering = YES;
    
    [self styleElements];
    [self filterSetup];
    [self notificationSetup];
}


#pragma mark - viewWillAppear()

- (void)viewWillAppear:(BOOL)animated {
    /*
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
    
    // Load info again
    [self loadBasicProfile];
    [self loadPastOpportunityArray];
    
    // Distance button text update
    [self.distanceButton setTitle:[NSString stringWithFormat:@"≤ %@ mi", [NSNumber numberWithDouble:[defaults doubleForKey:@"maxDistance"]]] forState:UIControlStateNormal];
    */
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    navigationBar.barTintColor = [UIColor colorNamed:@"navColor"];
    self.tabBarController.tabBar.barTintColor = [UIColor colorNamed:@"navColor"];
}


#pragma mark - Load user's past opportunities

- (void)loadPastOpportunityArray {
    locationManager = [[CLLocationManager alloc] init];
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
    query.limit = 20;
    [query orderByDescending:createdAtQuery];
    [query whereKey:objectIdKey containedIn:self.pastOpportunities];
    
    // Fetch posts asynchronously
    [query findObjectsInBackgroundWithBlock:^(NSArray *opportunities, NSError *error) {
        if (opportunities != nil) {
            self.unprocessedOpportunities = opportunities;
            
            // Get user location
            [self getCurrentLocation];
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
    [locationManager stopUpdatingLocation];
    locationManager = nil;
    
    // Create and store array of Opportunity objects from retrieved posts
    [Opportunity createOpportunityArray:self.unprocessedOpportunities withLocation:self.userLocation withController:self];
    self.filteredOpportunities = self.opportunities;
    
    //[self.tableView reloadData];
    //[self.refreshControl endRefreshing];
}

- (void)finishOpportunitySetup:(NSMutableArray *)opportunities {
    self.opportunities = opportunities;
    self.filteredOpportunities = self.opportunities;
    
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(stopAnimation) userInfo:nil repeats:NO];
}


#pragma mark - Set map view markers

- (void)placeMarker:(Organization *)organization {
    CLLocationCoordinate2D position = CLLocationCoordinate2DMake([organization.destinationLatValue doubleValue], [organization.destinationLngValue doubleValue]);
    GMSMarker *marker = [GMSMarker markerWithPosition:position];
    marker.title = organization.username;
    marker.icon = [GMSMarker markerImageWithColor:[UIColor colorNamed:@"themeColor"]];
    marker.map = self.mapView;
    
    // Re-centering map
    self.mapView.camera = [GMSCameraPosition cameraWithLatitude:[organization.destinationLatValue doubleValue] longitude:[organization.destinationLngValue doubleValue] zoom:10];
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
}


#pragma mark - Filter controls

- (IBAction)didTapVolunteerFilter:(id)sender {
    // Toggles button color
    if (self.volunteerFilterOn) {
        self.volunteerButton.backgroundColor = [UIColor colorWithRed:73/255.0 green:93/255.0 blue:1 alpha:1];
        [self.filters removeObject:volunteeringFilter];
    } else {
        self.volunteerButton.backgroundColor = [UIColor colorWithRed:47/255.0 green:59/255.0 blue:161/255.0 alpha:1];
        [self.filters addObject:volunteeringFilter];
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
    } else {
        self.shadowButton.backgroundColor = [UIColor colorWithRed:47/255.0 green:59/255.0 blue:161/255.0 alpha:1];
        [self.filters addObject:shadowingFilter];
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
    } else {
        self.donateButton.backgroundColor = [UIColor colorWithRed:47/255.0 green:59/255.0 blue:161/255.0 alpha:1];
        [self.filters addObject:donationFilter];
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
    } else {
        self.distanceButton.backgroundColor = [UIColor colorWithRed:47/255.0 green:59/255.0 blue:161/255.0 alpha:1];
        [self.filters addObject:distanceFilter];
    }
    
    // Toggles filter on/off state
    self.distanceFilterOn = !self.distanceFilterOn;
    
    // Manually trigger search and refilter using updated filters
    [self searchBar:self.searchBar textDidChange: self.searchBar.text];
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
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
    [cell setCell:self.filteredOpportunities[indexPath.row]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredOpportunities.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {

    // remove bottom extra 20px space.
    return CGFLOAT_MIN;
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
                    NSMutableArray *userTags = user[tagsQuery];
                    for (NSString *tag in opportunity.tags) {
                        NSUInteger index = [userTags indexOfObject:tag];
                        [userTags removeObjectAtIndex:index];
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
        UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alert addAction:yesAction];
        [alert addAction:noAction];
        [self presentViewController:alert animated:YES completion:^{
        }];
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
        [self presentViewController:alert animated:YES completion:^{
        }];
    } else {
        // If user does not have camera, they can only chooe from camera roll
        imagePickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        // Present image picker controller
        [self presentViewController:imagePickerVC animated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    // Get the image captured by the UIImagePickerController and store it
    //UIImage *originalImage = info[UIImagePickerControllerOriginalImage];
    UIImage *editedImage = info[UIImagePickerControllerEditedImage];
    CGSize imageSize = CGSizeMake(300, 300);
    UIImage *resizedImage = [self resizeImage:editedImage withSize:imageSize];
    self.updatedProfileImage = resizedImage;
    
    [self saveImage];
    
    // Do something with the images (based on your use case)
    
    
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
            
            // Adding a slight delay so progress HUD doesn't just flash
            [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(stopAnimation) userInfo:nil repeats:NO];
        }];
    });
}


#pragma mark - Search Bar

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    if (searchText.length != 0) {
        // Searches for objects containing what the user types
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(text CONTAINS[cd] %@)", searchText];
        
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
    self.searchBar.text = @"";
    [self.searchBar resignFirstResponder];
}


#pragma mark - Setup styling

- (void)styleElements {
    // Round profile images
    self.profileImageView.layer.cornerRadius = 50;
    
    // Search bar placeholder text
    self.searchBar.placeholder = @"Search your opportunities...";
    
    // Buttons have rounded corners
    self.volunteerButton.layer.cornerRadius = 15;
    self.shadowButton.layer.cornerRadius = 15;
    self.donateButton.layer.cornerRadius = 15;
    self.distanceButton.layer.cornerRadius = 15;
    
    // Button colors
    self.volunteerButton.backgroundColor = [UIColor colorWithRed:73/255.0 green:93/255.0 blue:1 alpha:1];
    self.shadowButton.backgroundColor = [UIColor colorWithRed:73/255.0 green:93/255.0 blue:1 alpha:1];
    self.donateButton.backgroundColor = [UIColor colorWithRed:73/255.0 green:93/255.0 blue:1 alpha:1];
    self.distanceButton.backgroundColor = [UIColor colorWithRed:73/255.0 green:93/255.0 blue:1 alpha:1];
    
    // Distance button text
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self.distanceButton setTitle:[NSString stringWithFormat:@"≤ %@ mi", [NSNumber numberWithDouble:[defaults doubleForKey:@"maxDistance"]]] forState:UIControlStateNormal];
    
    // Map corner radius
    self.mapView.layer.cornerRadius = 10;
    
    // Map user location enabled
    self.mapView.myLocationEnabled = true;
    
    // Search bar styling
    self.searchBar.layer.borderColor = [[UIColor colorNamed:@"borderColor"] CGColor];
    self.searchBar.layer.borderWidth = 1;
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


#pragma mark - UIColor with hex

-(UIColor *)colorWithHex:(UInt32)col {
    unsigned char r, g, b;
    b = col & 0xFF;
    g = (col >> 8) & 0xFF;
    r = (col >> 16) & 0xFF;
    return [UIColor colorWithRed:(float)r/255.0f green:(float)g/255.0f blue:(float)b/255.0f alpha:1];
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
    }
}

@end
