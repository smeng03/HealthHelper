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

@interface OpportunitiesViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, CLLocationManagerDelegate>

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
@property (strong, nonatomic) NSNumber *latValue;
@property (strong, nonatomic) NSNumber *lngValue;
@property (strong, nonatomic) NSArray *unprocessedOpportunities;

@end

@implementation OpportunitiesViewController

CLLocationManager *opportunitiesLocationManager;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Table view delegate and data source
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Search bar delegate and data source
    self.searchBar.delegate = self;
    
    // Setting initial theme to light mode
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:false forKey:@"dark_mode_on"];
    [defaults setInteger:0xf7f7f7 forKey:@"nav_color"];
    [defaults synchronize];
    
    // Load opportunities
    [self loadOpportunities];
    
    // Search bar placeholder text
    self.searchBar.placeholder = @"Search opportunities...";
    
    // Refresh Control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(loadOpportunities) forControlEvents:UIControlEventValueChanged];
    
    // Places refresher at correct location
    [self.tableView insertSubview:self.refreshControl atIndex:0];
    
    // Buttons have rounded corners
    self.volunteerButton.layer.cornerRadius = 15;
    self.shadowButton.layer.cornerRadius = 15;
    self.donateButton.layer.cornerRadius = 15;
    self.distanceButton.layer.cornerRadius = 15;
    
    // Initialize filter values
    self.volunteerFilterOn = FALSE;
    self.shadowFilterOn = FALSE;
    self.donateFilterOn = FALSE;
    self.distanceFilterOn = FALSE;
    
    // Initialize filters array
    self.filters = [NSMutableArray new];
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

- (void)loadOpportunities {
    opportunitiesLocationManager = [[CLLocationManager alloc] init];
    
    // Construct query
    PFQuery *query = [PFQuery queryWithClassName:@"Opportunity"];
    [query includeKey:@"description"];
    [query includeKey:@"tags"];
    [query includeKey:@"signUpLink"];
    [query includeKey:@"opportunityType"];
    [query includeKey:@"author"];
    [query includeKey:@"author.image"];
    [query includeKey:@"author.description"];
    [query includeKey:@"author.address"];
    [query includeKey:@"author.totalScore"];
    [query includeKey:@"author.numReviews"];
    [query includeKey:@"author.reviews"];
    [query includeKey:@"donationAmount"];
    [query includeKey:@"hours"];
    [query includeKey:@"date"];
    [query includeKey:@"position"];
    query.limit = 20;
    [query orderByDescending:@"createdAt"];
    
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

- (void)getCurrentLocation {
    // Get current user location
    opportunitiesLocationManager.delegate = self;
    opportunitiesLocationManager.desiredAccuracy = kCLLocationAccuracyBest;
    [opportunitiesLocationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *location = [locations lastObject];
    self.latValue = [NSNumber numberWithDouble:location.coordinate.latitude];
    self.lngValue = [NSNumber numberWithDouble:location.coordinate.longitude];
    [opportunitiesLocationManager stopUpdatingLocation];
    opportunitiesLocationManager = nil;
    
    // Create and store array of Opportunity objects from retrieved posts
    self.opportunities = [Opportunity createOpportunityArray:self.unprocessedOpportunities withLat:self.latValue withLng:self.lngValue];
    self.filteredOpportunities = self.opportunities;
    
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
}

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

// UIColor from hex color
-(UIColor *)colorWithHex:(UInt32)col {
    unsigned char r, g, b;
    b = col & 0xFF;
    g = (col >> 8) & 0xFF;
    r = (col >> 16) & 0xFF;
    return [UIColor colorWithRed:(float)r/255.0f green:(float)g/255.0f blue:(float)b/255.0f alpha:1];
}

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


// FILTERING CODE
-(void)applyFilters:(NSArray *)filteredData {
    // Applies all selected filters to a given list of opportunities
    for (NSString *filter in self.filters) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(opportunityType CONTAINS[cd] %@)", filter];
        filteredData = [filteredData filteredArrayUsingPredicate:predicate];
    }
    self.filteredOpportunities = [filteredData mutableCopy];
}

- (IBAction)didTapVolunteerFilter:(id)sender {
    // Toggles button color
    if (self.volunteerFilterOn) {
        self.volunteerButton.backgroundColor = [UIColor systemGray4Color];
        [self.filters removeObject:@"Volunteering"];
    } else {
        self.volunteerButton.backgroundColor = [UIColor systemGrayColor];
        [self.filters addObject:@"Volunteering"];
    }
    
    // Toggles filter on/off state
    self.volunteerFilterOn = !self.volunteerFilterOn;
    
    // Manually trigger search and refilter using updated filters
    [self searchBar:self.searchBar textDidChange: self.searchBar.text];
}

- (IBAction)didTapShadowFilter:(id)sender {
    // Toggles button color
    if (self.shadowFilterOn) {
        self.shadowButton.backgroundColor = [UIColor systemGray4Color];
        [self.filters removeObject:@"Shadowing"];
    } else {
        self.shadowButton.backgroundColor = [UIColor systemGrayColor];
        [self.filters addObject:@"Shadowing"];
    }
    
    // Toggles filter on/off state
    self.shadowFilterOn = !self.shadowFilterOn;
    
    // Manually trigger search and refilter using updated filters
    [self searchBar:self.searchBar textDidChange: self.searchBar.text];
}

- (IBAction)didTapDonateFilter:(id)sender {
    // Toggles button color
    if (self.donateFilterOn) {
        self.donateButton.backgroundColor = [UIColor systemGray4Color];
        [self.filters removeObject:@"Donation"];
    } else {
        self.donateButton.backgroundColor = [UIColor systemGrayColor];
        [self.filters addObject:@"Donation"];
    }
    
    // Toggles filter on/off state
    self.donateFilterOn = !self.donateFilterOn;
    
    // Manually trigger search and refilter using updated filters
    [self searchBar:self.searchBar textDidChange: self.searchBar.text];
}

- (IBAction)didTapDistanceFilter:(id)sender {
    // Toggles button color
    if (self.volunteerFilterOn) {
        self.distanceButton.backgroundColor = [UIColor systemGray4Color];
        //[self.filters removeObject:@"Volunteering"];
    } else {
        self.distanceButton.backgroundColor = [UIColor systemGrayColor];
        //[self.filters addObject:@"Volunteering"];
    }
    
    // Toggles filter on/off state
    self.distanceFilterOn = !self.distanceFilterOn;
    
    // Manually trigger search and refilter using updated filters
    [self searchBar:self.searchBar textDidChange: self.searchBar.text];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Identify tapped cell and get associated opportunity
    UITableViewCell *tappedCell = sender;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:tappedCell];
    Opportunity *opportunity = self.filteredOpportunities[indexPath.row];
    
    // Send information
    DetailsViewController *detailsViewController = [segue destinationViewController];
    detailsViewController.opportunity = opportunity;
}

@end
