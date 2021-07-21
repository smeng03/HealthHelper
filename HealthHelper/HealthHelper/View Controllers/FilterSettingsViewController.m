//
//  FilterSettingsViewController.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/21/21.
//

#import "FilterSettingsViewController.h"

@interface FilterSettingsViewController ()

@property (weak, nonatomic) IBOutlet UITextField *distanceField;

@end

@implementation FilterSettingsViewController

#pragma mark - viewDidLoad()

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.distanceField.text = [NSString stringWithFormat:@"%@", [NSNumber numberWithDouble:[defaults doubleForKey:@"maxDistance"]]];
}

- (IBAction)didSave:(id)sender {
    NSNumberFormatter *f = [[NSNumberFormatter alloc] init];
    f.numberStyle = NSNumberFormatterDecimalStyle;
    NSNumber *maxDistance = [f numberFromString:self.distanceField.text];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble:[maxDistance doubleValue] forKey:@"maxDistance"];
    [defaults synchronize];
    
    [self.delegate didUpdateDistance];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didTapCancel:(id)sender {
    // Dismisses ComposeViewController
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)dismissKeyboard:(id)sender {
    // Dismisses keyboard when screen is tapped
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
