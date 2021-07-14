//
//  SettingsViewController.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/12/21.
//

#import "SettingsViewController.h"

@interface SettingsViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *darkModeSwitch;

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Dark mode switch initialized to off (since default is light mode)
    [self.darkModeSwitch setOn:NO animated:YES];
}

- (void)viewWillAppear:(BOOL)animated{
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

- (IBAction)didToggleDarkMode:(id)sender {
    // Checks existing status
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    bool darkModeStatus = [defaults boolForKey:@"dark_mode_on"];
    
    // Toggles status if switch is toggled
    if (darkModeStatus) {
        darkModeStatus = false;
    }
    else {
        darkModeStatus = true;
    }
    [defaults setBool:darkModeStatus forKey:@"dark_mode_on"];
    [defaults synchronize];
    
    // Reload the view
    [self viewWillAppear:true];
}

- (IBAction)setColor1:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:0x273599 forKey:@"nav_color"];
    [defaults synchronize];
    
    [self viewWillAppear:true];
}

- (IBAction)setColor2:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:0xFFE07A forKey:@"nav_color"];
    [defaults synchronize];
    
    [self viewWillAppear:true];
}

- (IBAction)setColor3:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:0xBBEA93 forKey:@"nav_color"];
    [defaults synchronize];
    
    [self viewWillAppear:true];
}

- (IBAction)setColor4:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:0xFFE0E5 forKey:@"nav_color"];
    [defaults synchronize];
    
    [self viewWillAppear:true];
}

- (IBAction)setColor5:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:0x333333 forKey:@"nav_color"];
    [defaults synchronize];
    
    [self viewWillAppear:true];
}

- (IBAction)resetColor:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:0xf7f7f7 forKey:@"nav_color"];
    [defaults synchronize];
    
    [self viewWillAppear:true];
}

// UIColor from hex color
-(UIColor *)colorWithHex:(UInt32)col {
    unsigned char r, g, b;
    b = col & 0xFF;
    g = (col >> 8) & 0xFF;
    r = (col >> 16) & 0xFF;
    return [UIColor colorWithRed:(float)r/255.0f green:(float)g/255.0f blue:(float)b/255.0f alpha:1];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
