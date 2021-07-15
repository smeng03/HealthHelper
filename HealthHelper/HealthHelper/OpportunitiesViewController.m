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

@interface OpportunitiesViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *opportunities;

@end

@implementation OpportunitiesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Table view delegate and data source
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Setting initial theme to light mode
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:false forKey:@"dark_mode_on"];
    [defaults setInteger:0xf7f7f7 forKey:@"nav_color"];
    [defaults synchronize];
    
    // Load opportunities
    [self loadOpportunities];
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
    [query includeKey:@"position"];
    query.limit = 20;
    [query orderByDescending:@"createdAt"];
    
    // Fetch posts asynchronously
    [query findObjectsInBackgroundWithBlock:^(NSArray *opportunities, NSError *error) {
        if (opportunities != nil) {
            // Create and store array of Post objects from retrieved posts
            self.opportunities = [Opportunity createOpportunityArray:opportunities];
            [self.tableView reloadData];
            //[self.refreshControl endRefreshing];
        } else {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    OpportunityCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"OpportunityCell"];
    
    // Setting cell and style
    [cell setCell:self.opportunities[indexPath.row]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.opportunities.count;
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
}

@end
