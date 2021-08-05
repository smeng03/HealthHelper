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
#import "Notification.h"
#import "OpportunityArray.h"
#import "OrganizationInfoViewController.h"

@interface OpportunitiesViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, CLLocationManagerDelegate, FilterSettingsControllerDelegate, OpportunityDelegate, OpportunityCellDelegate>

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
@property (strong, nonatomic) NSMutableDictionary *userTags;
@property (strong, nonatomic) NSArray *userPastOpportunities;
@property (weak, nonatomic) IBOutlet UIView *notificationView;
@property (weak, nonatomic) IBOutlet UILabel *notificationLabel;
@property (strong, nonatomic) NSCache *opportunitiesCache;
@property (assign, nonatomic) BOOL isFirstLoad;
@property (nonatomic, strong) NSString *units;
@property (nonatomic, strong) NSString *mode;
@property (weak, nonatomic) IBOutlet UIView *headerView;
@property (assign, nonatomic) BOOL firstLoadComplete;


@end

@implementation OpportunitiesViewController

CLLocationManager *opportunitiesLocationManager;

#pragma mark - viewDidLoad()

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.firstLoadComplete = FALSE;
    
    self.isFirstLoad = TRUE;
    [self setDefaults];
    
    // Delegates and data sources
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.searchBar.delegate = self;
    
    // Setting cache
    self.opportunitiesCache = [[NSCache alloc] init];
    
    // Load opportunities
    [self checkCache];
    
    // Refresh when app comes to foreground
    [[NSNotificationCenter defaultCenter] addObserverForName:@"EnteredForeground" object:nil queue:nil usingBlock:^(NSNotification *note) {
        [self viewWillAppear:TRUE];
    }];
    
    // Autorefresh feed
    // [NSTimer scheduledTimerWithTimeInterval:3600 target:self selector:@selector(loadUserFilters) userInfo:nil repeats:NO];
    
    [self styleElements];
    [self styleButton];
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
    
    [self reloadOpportunities];
    
}


#pragma mark - Reload opportunities

- (void)reloadOpportunities {
    
    // Reload opportunities when needed
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *units = [defaults objectForKey:@"units"];
    NSString *mode = [defaults objectForKey:@"mode"];
    if ([self.units isEqualToString:units] && [self.mode isEqualToString:mode]) {
        
        if (!self.isFirstLoad) {
            [self checkCache];
        }
        
    } else {
        
        [self loadUserFilters];
        self.units = units;
        self.mode = mode;
        
    }
    
    [self updateDistanceButtonText];
    self.isFirstLoad = FALSE;
    
    // Refresh view
    [self.headerView setNeedsDisplay];
    
}


#pragma mark - Check cache

- (void)checkCache {
    
    OpportunityArray *cachedOpportunities = [self.opportunitiesCache objectForKey:@"opportunities"];
    
    if (!cachedOpportunities) {
        
        // Load user filters and opportunities
        [self loadUserFilters];
        
    } else {
        
        self.opportunities = cachedOpportunities.opportunities;
        self.filteredOpportunities = self.opportunities;
        [self.tableView reloadData];
        
    }
    
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

- (void)sortOpportunitiesByRelevance:(NSMutableArray *)opportunities {
    
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
                        similarityScore += [self.userTags[userTag] intValue];
                    }
                    
                }
            }
        } else {
            
            // Put signed up opportunities at the bottom of the list
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
    
    // Save to cache
    OpportunityArray *array = [OpportunityArray new];
    [array setOpportunityArray:self.opportunities];
    [self.opportunitiesCache setObject:array forKey:@"opportunities"];
    
}

- (void)sortOpportunitiesByNewest:(NSMutableArray *)opportunities {
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeCreatedAt"
                                               ascending:NO];
    NSArray *sortedOpportunities = [[opportunities copy] sortedArrayUsingDescriptors:@[sortDescriptor]];
    self.opportunities = [sortedOpportunities mutableCopy];
    self.filteredOpportunities = self.opportunities;
    
    // Save to cache
    OpportunityArray *array = [OpportunityArray new];
    [array setOpportunityArray:self.opportunities];
    [self.opportunitiesCache setObject:array forKey:@"opportunities"];
    
}

- (void)sortOpportunitiesByClosest:(NSMutableArray *)opportunities {
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"author.distanceValue"
                                               ascending:YES];
    NSArray *sortedOpportunities = [[opportunities copy] sortedArrayUsingDescriptors:@[sortDescriptor]];
    self.opportunities = [sortedOpportunities mutableCopy];
    self.filteredOpportunities = self.opportunities;
    
    // Save to cache
    OpportunityArray *array = [OpportunityArray new];
    [array setOpportunityArray:self.opportunities];
    [self.opportunitiesCache setObject:array forKey:@"opportunities"];
    
}


#pragma mark - Table View

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    OpportunityCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"OpportunityCell"];
    
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

    // remove bottom extra 20px space.
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
    
    [self sortOpportunitiesByRelevance:opportunities];
    
    self.firstLoadComplete = TRUE;
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
    [self stopAnimation];
    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
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


#pragma mark - Setup styling

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

- (void)filterSetup {
    
    // Initialize filter values
    self.volunteerFilterOn = FALSE;
    self.shadowFilterOn = FALSE;
    self.donateFilterOn = FALSE;
    self.distanceFilterOn = FALSE;
    
    // Initialize filters array
    self.filters = [NSMutableArray new];
    
}

- (void)styleElements {
    
    // Setting default nav color
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"navColor" forKey:@"nav_color"];
    [defaults synchronize];
    
    // Search bar placeholder text
    self.searchBar.placeholder = @"Search opportunities...";
    
    // Refresh Control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(loadUserFilters) forControlEvents:UIControlEventValueChanged];
    [self.tableView insertSubview:self.refreshControl atIndex:0];
    
}


#pragma mark - Distance settings delegate method

- (void)didUpdateDistance:(int)sortType {
    
    [self updateDistanceButtonText];
    
    if (sortType == 0) {
        
        [self sortOpportunitiesByRelevance:self.opportunities];
        
    } else if (sortType == 1) {
        
        [self sortOpportunitiesByClosest:self.opportunities];
        
    } else {
        
        [self sortOpportunitiesByNewest:self.opportunities];
        
    }
    
    // Manually trigger search and refilter using updated distance filter
    [self searchBar:self.searchBar textDidChange: self.searchBar.text];
    
}


#pragma mark - Update distance button text

- (void)updateDistanceButtonText {
    
    // Distance button text
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *units;
    
    if ([self.units isEqualToString:@"imperial"]) {
        units = @"mi";
    } else {
        units = @"km";
    }
    
    [self.distanceButton setTitle:[NSString stringWithFormat:@"≤ %@ %@", [NSNumber numberWithDouble:[defaults doubleForKey:@"maxDistance"]], units] forState:UIControlStateNormal];
    
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

-(void)stopAnimation {
    // Stopping progress bar
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });
}

- (void)setDefaults {
    
    // Set default distance filter, units, and method of travel
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble:10.0 forKey:@"maxDistance"];
    [defaults setObject:@"imperial" forKey:@"units"];
    [defaults setObject:@"driving" forKey:@"mode"];
    [defaults setInteger:0 forKey:@"sortSegment"];
    [defaults setInteger:0 forKey:@"unitsSegment"];
    [defaults setInteger:0 forKey:@"modeSegment"];
    [defaults synchronize];
    self.units = @"imperial";
    self.mode = @"driving";
    
}


#pragma mark - Segue to organization details

- (void)didTapOrganizationProfile:(Opportunity *)opportunity {
    
    [self performSegueWithIdentifier:@"toOrganizationDetails2" sender:opportunity];
    
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
        detailsViewController.userLocation = self.userLocation;
        
    } else if ([segue.identifier isEqualToString:@"toFilterSettings"]) {
        
        FilterSettingsViewController *filterSettingsViewController = [segue destinationViewController];
        filterSettingsViewController.delegate = self;
        filterSettingsViewController.units = self.units;
        
    } else if ([segue.identifier isEqualToString:@"toOrganizationDetails2"]) {
        
        OrganizationInfoViewController *organizationInfoViewController = [segue destinationViewController];
        organizationInfoViewController.opportunity = sender;
        
    }
    
}

@end
