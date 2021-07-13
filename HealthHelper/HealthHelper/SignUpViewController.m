//
//  SignUpViewController.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/12/21.
//

#import <QuartzCore/QuartzCore.h>
#import "SignUpViewController.h"
#import <Parse/Parse.h>

@interface SignUpViewController ()

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UITextField *confirmPasswordField;
@property (weak, nonatomic) IBOutlet UIButton *signUpButton;

@end

@implementation SignUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Rounded button corners
    self.signUpButton.layer.cornerRadius = 10;
    
    // Obscures password
    self.passwordField.secureTextEntry = YES;
    self.confirmPasswordField.secureTextEntry = YES;
}

- (IBAction)didTapSignUp:(id)sender {
    // Initialize a user object
    PFUser *newUser = [PFUser user];
    
    // Set user properties
    newUser.username = self.usernameField.text;
    newUser.password = self.passwordField.text;
    
    if ([self.passwordField.text isEqualToString:self.confirmPasswordField.text]) {
        // Call sign up function on the object
        [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
            if (error != nil) {
                // Display alert of registration failed
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:[NSString stringWithFormat:@"Error: %@", error.localizedDescription] preferredStyle:(UIAlertControllerStyleAlert)];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
                [alert addAction:okAction];
                [self presentViewController:alert animated:YES completion:^{
                }];
            } else {
                NSLog(@"User registered successfully");
                
                // Set default profile image
                [self setProfileImage];

                // Manually segue to logged in view
                [self performSegueWithIdentifier:@"signUpSegue" sender:nil];
            }
        }];
    } else {
        // Passwords do not match, need to re-enter
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Passwords do not match, please try again" preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:^{
        }];
    }
}

- (IBAction)dismissKeyboard:(id)sender {
    // Dismisses keyboard when screen is tapped
    [self.view endEditing:YES];
}

- (void)setProfileImage {
    // Save default profile image to current user object
    NSData *imageData = UIImagePNGRepresentation([UIImage imageNamed:@"user2"]);
    PFUser *user = PFUser.currentUser;
    user[@"image"] = [PFFileObject fileObjectWithName:@"image.png" data:imageData contentType:@"image/png"];
    
    // Save to database
    [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
        if (succeeded) {
            NSLog(@"Success!");
        } else {
            // Otherwise, displays an alert
            NSLog(@"Problem creating profile: %@", error.localizedDescription);
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Error posting image." preferredStyle:(UIAlertControllerStyleAlert)];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
            [alert addAction:okAction];
            [self presentViewController:alert animated:YES completion:^{}];
        }
    }];
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
