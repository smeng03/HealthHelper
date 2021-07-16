//
//  OrganizationInfoViewController.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/14/21.
//

#import "OrganizationInfoViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <SDWebImage/SDWebImage.h>
#import "ComposeViewController.h"

@interface OrganizationInfoViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *organizationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *reviewButton;

@end

@implementation OrganizationInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Nav bar title
    self.navigationItem.title = self.opportunity.author.username;
    
    // Rounded profile images
    self.profileImageView.layer.cornerRadius = 50;
    
    // Rounded corners on button
    self.reviewButton.layer.cornerRadius = 5;
    
    // Set organization name
    self.organizationNameLabel.text = self.opportunity.author.username;
    
    // Set organization decription
    self.descriptionLabel.text = self.opportunity.author.text;
    
    // Set organization profile picture
    [self.profileImageView sd_setImageWithURL:[NSURL URLWithString:self.opportunity.author.imageURL]];
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

// UIColor from hex color
-(UIColor *)colorWithHex:(UInt32)col {
    unsigned char r, g, b;
    b = col & 0xFF;
    g = (col >> 8) & 0xFF;
    r = (col >> 16) & 0xFF;
    return [UIColor colorWithRed:(float)r/255.0f green:(float)g/255.0f blue:(float)b/255.0f alpha:1];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqual:@"composeSegue"]) {
        // Sending current opportunity to next view controller
        ComposeViewController *composeViewController = [segue destinationViewController];
        composeViewController.opportunity = self.opportunity;
    }
}

@end
