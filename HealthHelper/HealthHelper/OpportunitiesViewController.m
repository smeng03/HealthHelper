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

@interface OpportunitiesViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

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

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    OpportunityCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"OpportunityCell"];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 20;
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
