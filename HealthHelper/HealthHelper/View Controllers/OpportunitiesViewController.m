//
//  OpportunitiesViewController.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/12/21.
//

#import "OpportunitiesViewController.h"
#import "OpportunityCell.h"
#import "DetailsViewController.h"
#import <Parse/Parse.h>
#import "SceneDelegate.h"
#import "LoginViewController.h"
#import "Opportunity.h"
#import "DetailsViewController.h"
#import "MBProgressHUD.h"
#import "QueryConstants.h"
#import "FilterConstants.h"
#import "FilterSettingsViewController.h"

@interface OpportunitiesViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, CLLocationManagerDelegate, FilterSettingsControllerDelegate, OpportunityDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *opportunities;
@property (strong, nonatomic) NSMutableArray *filteredOpportunities;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (weak, nonatomic) IBOutlet UIButton *volunteerButton;
@property (weak, nonatomic) IBOutlet UIButton *shadowButton;
@property (weak, nonatomic) IBOutlet UIButton *donateButton;
@property (weak, nonatomic) IBOutlet UIButton *distanceButton;
@property (nonatomic, assign) BOOL volunteerFilterOn;
@property (nonatomic, assign) BOOL shadowFilterOn;
@property (nonatomic, assign) BOOL donateFilterOn;
@property (nonatomic, assign) BOOL distanceFilterOn;
@property (strong, nonatomic) NSMutableArray *filters;
@property (strong, nonatomic) CLLocation *userLocation;
@property (strong, nonatomic) NSArray *unprocessedOpportunities;
@property (strong, nonatomic) NSArray *userTags;
@property (strong, nonatomic) NSArray *userPastOpportunities;

@end

@implementation OpportunitiesViewController

CLLocationManager *opportunitiesLocationManager;

#pragma mark - viewDidLoad()

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Delegates and data sources
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.searchBar.delegate = self;
    
    // Setting initial theme to light mode
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:false forKey:@"dark_mode_on"];
    [defaults setInteger:0xf7f7f7 forKey:@"nav_color"];
    [defaults synchronize];
    
    // Load user filters and opportunities
    [self loadUserFilters];
    
    // Search bar placeholder text
    self.searchBar.placeholder = @"Search opportunities...";
    
    // Refresh Control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(loadOpportunities) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:self.refreshControl atIndex:0];
    
    // Set default distance filter
    [defaults setDouble:10.0 forKey:@"maxDistance"];
    [defaults synchronize];
    
    // Search bar styling
    self.searchBar.layer.borderColor = [[UIColor colorNamed:@"borderColor"] CGColor];
    self.searchBar.layer.borderWidth = 1;
    
    [self styleButton];
    [self filterSetup];
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
     */
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    navigationBar.barTintColor = [UIColor colorNamed:@"navColor"];
    self.tabBarController.tabBar.barTintColor = [UIColor colorNamed:@"navColor"];
}


#pragma mark - Load user filters

- (void)loadUserFilters {
    // Querying for profile image
    PFQuery *query = [PFUser query];
    [query includeKey:userTagsQuery];
    [query includeKey:pastOpportunitiesQuery];
    [query whereKey:objectIdKey equalTo:PFUser.currentUser.objectId];
    
    // Fetch user asynchronously
    [query findObjectsInBackgroundWithBlock:^(NSArray *users, NSError *error) {
        if (users != nil) {
            PFUser *user = users[0];
            
            self.userTags = user[userTagsQuery];
            self.userPastOpportunities = user[pastOpportunitiesQuery];
            
            [self loadOpportunities];
            
        } else {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}


#pragma mark - Load opportunities array

- (void)loadOpportunities {
    opportunitiesLocationManager = [[CLLocationManager alloc] init];
    
    CLAuthorizationStatus status = CLLocationManager.authorizationStatus;
    if (status != kCLAuthorizationStatusAuthorizedWhenInUse || status != kCLAuthorizationStatusAuthorizedAlways) {
        [opportunitiesLocationManager requestWhenInUseAuthorization];
    }
    
    // Construct query
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
    
    // Fetch posts asynchronously
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        [query findObjectsInBackgroundWithBlock:^(NSArray *opportunities, NSError *error) {
            if (opportunities != nil) {
                self.unprocessedOpportunities = opportunities;
                
                // Get user location
                [self getCurrentLocation];
            } else {
                NSLog(@"%@", error.localizedDescription);
            }
        }];
    });
}


#pragma mark - Sort opportunities

- (void)sortOpportunities:(NSMutableArray *)opportunities {
    NSMutableArray *opportunitiesWithScores = [NSMutableArray new];
    NSMutableArray *sortedOpportunityArray = [NSMutableArray new];
    
    // Calculate similarity scores
    for (Opportunity *opportunity in opportunities) {
        int similarityScore;
        
        if (![self.userPastOpportunities containsObject:opportunity.opportunityId]) {
            similarityScore = 0;
            for (NSString *opportunityTag in opportunity.tags) {
                for (NSString *userTag in self.userTags) {
                    if ([opportunityTag isEqualToString:userTag]) {
                        similarityScore += 1;
                    }
                }
            }
        } else {  // Put signed up opportunities at the bottom of the list
            similarityScore = -1;
        }
    
    [opportunitiesWithScores addObject:@{@"opportunity": opportunity, @"score":[NSNumber numberWithInt:similarityScore]}];
    }
    
    // Sorting opportunities
    NSArray *sortedOpportunities = [opportunitiesWithScores sortedArrayUsingDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"score" ascending:NO]]];
    
    // Storing sorted opportunities
    for (Opportunity *sortedOpportunityDict in sortedOpportunities) {
        Opportunity *sortedOpportunity = sortedOpportunityDict[@"opportunity"];
        [sortedOpportunityArray addObject:sortedOpportunity];
    }
    
    self.opportunities = sortedOpportunityArray;
    self.filteredOpportunities = self.opportunities;
}


#pragma mark - Table View

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    OpportunityCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"OpportunityCell"];
    
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


#pragma mark - Get user location

- (void)getCurrentLocation {
    // Get current user location
    opportunitiesLocationManager.delegate = self;
    opportunitiesLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [opportunitiesLocationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    self.userLocation = location;
    [opportunitiesLocationManager stopUpdatingLocation];
    opportunitiesLocationManager = nil;
    // Create and store array of Opportunity objects from retrieved posts
    [Opportunity createOpportunityArray:self.unprocessedOpportunities withLocation:self.userLocation withController:self];
}

- (void)finishOpportunitySetup:(NSMutableArray *)opportunities {
    [self sortOpportunities:opportunities];
    
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
    
    // Adding a slight delay so progress HUD doesn't just flash
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(stopAnimation) userInfo:nil repeats:NO];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
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
    [self.searchBar resignFirstResponder];
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


#pragma mark - Setup styling

- (void)styleButton {
    // Buttons have rounded corners
    self.volunteerButton.layer.cornerRadius = 15;
    self.shadowButton.layer.cornerRadius = 15;
    self.donateButton.layer.cornerRadius = 15;
    self.distanceButton.layer.cornerRadius = 15;
    
    // Distance button text
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self.distanceButton setTitle:[NSString stringWithFormat:@"≤ %@ mi", [NSNumber numberWithDouble:[defaults doubleForKey:@"maxDistance"]]] forState:UIControlStateNormal];
    
    // Button colors
    self.volunteerButton.backgroundColor = [UIColor colorWithRed:73/255.0 green:93/255.0 blue:1 alpha:1];
    self.shadowButton.backgroundColor = [UIColor colorWithRed:73/255.0 green:93/255.0 blue:1 alpha:1];
    self.donateButton.backgroundColor = [UIColor colorWithRed:73/255.0 green:93/255.0 blue:1 alpha:1];
    self.distanceButton.backgroundColor = [UIColor colorWithRed:73/255.0 green:93/255.0 blue:1 alpha:1];
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


#pragma mark - Distance settings delegate method

- (void)didUpdateDistance {
    // Distance button text update
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self.distanceButton setTitle:[NSString stringWithFormat:@"≤ %@ mi", [NSNumber numberWithDouble:[defaults doubleForKey:@"maxDistance"]]] forState:UIControlStateNormal];
    
    // Manually trigger search and refilter using updated distance filter
    [self searchBar:self.searchBar textDidChange: self.searchBar.text];
}


#pragma mark - UIColor from hex

-(UIColor *)colorWithHex:(UInt32)col {
    unsigned char r, g, b;
    b = col & 0xFF;
    g = (col >> 8) & 0xFF;
    r = (col >> 16) & 0xFF;
    return [UIColor colorWithRed:(float)r/255.0f green:(float)g/255.0f blue:(float)b/255.0f alpha:1];
}


#pragma mark - Other functions

-(void)stopAnimation {
    // Stopping progress bar
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"opportunitiesToDetails"]) {
        // Identify tapped cell and get associated opportunity
        UITableViewCell *tappedCell = sender;
        NSIndexPath *indexPath = [self.tableView indexPathForCell:tappedCell];
        Opportunity *opportunity = self.filteredOpportunities[indexPath.row];
        
        // Send information
        DetailsViewController *detailsViewController = [segue destinationViewController];
        detailsViewController.opportunity = opportunity;
    } else if ([segue.identifier isEqualToString:@"toFilterSettings"]) {
        FilterSettingsViewController *filterSettingsViewController = [segue destinationViewController];
        filterSettingsViewController.delegate = self;
    }
}

@end
