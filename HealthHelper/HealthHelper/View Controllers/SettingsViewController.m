//
//  SettingsViewController.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/12/21.
//

#import "SettingsViewController.h"
#import "Notification.h"
#import <QuartzCore/QuartzCore.h>

@interface SettingsViewController ()

@property (weak, nonatomic) IBOutlet UIView *notificationView;
@property (weak, nonatomic) IBOutlet UILabel *notificationLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *distanceUnitsControl;
@property (weak, nonatomic) IBOutlet UISegmentedControl *modeOfTravelControl;
@property (weak, nonatomic) IBOutlet UIButton *color1Button;
@property (weak, nonatomic) IBOutlet UIButton *color2Button;
@property (weak, nonatomic) IBOutlet UIButton *color3Button;
@property (weak, nonatomic) IBOutlet UIButton *color4Button;
@property (weak, nonatomic) IBOutlet UIButton *color5Button;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;

@end

@implementation SettingsViewController

#pragma mark - viewDidLoad()

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Allows notifications to be posted
    [self notificationSetup];
    
    // Default highlighted segments
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.distanceUnitsControl.selectedSegmentIndex = [defaults integerForKey:@"unitsSegment"];
    self.modeOfTravelControl.selectedSegmentIndex = [defaults integerForKey:@"modeSegment"];
    
    [self styleButtons];
    
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


#pragma mark - Changed units

- (IBAction)didChangeUnits:(id)sender {
    
    NSArray *units = @[@"imperial", @"metric"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:units[self.distanceUnitsControl.selectedSegmentIndex] forKey:@"units"];
    [defaults setInteger:self.distanceUnitsControl.selectedSegmentIndex forKey:@"unitsSegment"];
    [defaults synchronize];
    
}


#pragma mark - Changed mode of travel

- (IBAction)didChangeModeofTravel:(id)sender {
    
    NSArray *modes = @[@"driving", @"walking", @"bicycling"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:modes[self.modeOfTravelControl.selectedSegmentIndex] forKey:@"mode"];
    [defaults setInteger:self.modeOfTravelControl.selectedSegmentIndex forKey:@"modeSegment"];
    [defaults synchronize];
    
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


#pragma mark - Nav Bar Colors

- (IBAction)setColor1:(id)sender {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"color1" forKey:@"nav_color"];
    [defaults synchronize];
    
    [self viewWillAppear:true];
    
}

- (IBAction)setColor2:(id)sender {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"color2" forKey:@"nav_color"];
    [defaults synchronize];
    
    [self viewWillAppear:true];
    
}

- (IBAction)setColor3:(id)sender {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"color3" forKey:@"nav_color"];
    [defaults synchronize];
    
    [self viewWillAppear:true];
    
}

- (IBAction)setColor4:(id)sender {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"color4" forKey:@"nav_color"];
    [defaults synchronize];
    
    [self viewWillAppear:true];
    
}

- (IBAction)setColor5:(id)sender {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"color5" forKey:@"nav_color"];
    [defaults synchronize];
    
    [self viewWillAppear:true];
    
}

- (IBAction)resetColor:(id)sender {
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@"navColor" forKey:@"nav_color"];
    [defaults synchronize];
    
    [self viewWillAppear:true];
    
}


#pragma mark - Style buttons

- (void)styleButtons {
    
    self.color1Button.layer.cornerRadius = 10;
    self.color2Button.layer.cornerRadius = 10;
    self.color3Button.layer.cornerRadius = 10;
    self.color4Button.layer.cornerRadius = 10;
    self.color5Button.layer.cornerRadius = 10;
    self.resetButton.layer.cornerRadius = 10;
    
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
