//
//  FilterSettingsViewController.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/21/21.
//

#import "FilterSettingsViewController.h"
#import "Notification.h"

@interface FilterSettingsViewController ()

@property (weak, nonatomic) IBOutlet UITextField *distanceField;
@property (weak, nonatomic) IBOutlet UIView *notificationView;
@property (weak, nonatomic) IBOutlet UILabel *notificationLabel;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;
@property (weak, nonatomic) IBOutlet UILabel *distanceLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *sortTypeControl;

@end

@implementation FilterSettingsViewController

#pragma mark - viewDidLoad()

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.distanceField.text = [NSString stringWithFormat:@"%@", [NSNumber numberWithDouble:[defaults doubleForKey:@"maxDistance"]]];
    
    // Allows notifications to be posted
    [self notificationSetup];
    
    // Default highlighted segments
    self.sortTypeControl.selectedSegmentIndex = [defaults integerForKey:@"sortSegment"];
    
}


#pragma mark - viewWillAppear()

- (void)viewWillAppear:(BOOL)animated {
    
    // Loads in user-picked color
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *navColor = [defaults objectForKey:@"nav_color"];
    
    // Set bar color
    self.navigationBar.barTintColor = [UIColor colorNamed:navColor];
    
    // Set distance label
    NSString *units;
    if ([self.units isEqualToString:@"imperial"]) {
        units = @"mi";
    } else {
        units = @"km";
    }
    self.distanceLabel.text = units;
    
}


#pragma mark - Save settings

- (IBAction)didSave:(id)sender {
    
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *maxDistance = [f numberFromString:self.distanceField.text];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble:[maxDistance doubleValue] forKey:@"maxDistance"];
    
    int sortType = (int)self.sortTypeControl.selectedSegmentIndex;
    [defaults setInteger:sortType forKey:@"sortSegment"];
    [defaults synchronize];
    
    [self.delegate didUpdateDistance:sortType];
    [self dismissViewControllerAnimated:YES completion:nil];
    
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


#pragma mark - Dismiss view controller

- (IBAction)didTapCancel:(id)sender {
    
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Dismiss keyboard

- (IBAction)dismissKeyboard:(id)sender {
    
    [self.view endEditing:YES];
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
