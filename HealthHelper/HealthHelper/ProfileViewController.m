//
//  ProfileViewController.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/12/21.
//

#import <QuartzCore/QuartzCore.h>
#import "ProfileViewController.h"
#import "PastOpportunityCell.h"
#import <Parse/Parse.h>
#import "SceneDelegate.h"
#import "LoginViewController.h"
#import "UIImageView+AFNetworking.h"
#import "MBProgressHUD.h"
#import <SDWebImage/SDWebImage.h>
#import "FBShimmering.h"
#import "FBShimmeringView.h"
#import "FBShimmeringLayer.h"

@interface ProfileViewController () <UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *hoursVolunteeredLabel;
@property (weak, nonatomic) IBOutlet UILabel *amountDonatedLabel;
@property (weak, nonatomic) IBOutlet UILabel *hoursShadowedLabel;
@property (strong, nonatomic) UIImage *updatedProfileImage;
@property (strong, nonatomic) PFUser *user;
@property (strong, nonatomic) FBShimmeringView *shimmeringView;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Table view data source and delegate
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Loading basic profile information
    [self loadBasicProfile];
    
    // Round profile images
    self.profileImageView.layer.cornerRadius = 50;
    
    [self.tableView reloadData];
    
    // Placeholder shimmer while loading
    // self.profileImageView.image = [SDAnimatedImage imageNamed:@"loading_square.gif"];
    self.shimmeringView = [[FBShimmeringView alloc] initWithFrame:self.profileImageView.frame];
    self.shimmeringView.contentView = self.profileImageView;
    [self.view addSubview:self.shimmeringView];
    self.shimmeringView.shimmering = YES;
    
    /*
    CGRect newFrame = self.shimmeringView.frame;
    newFrame.size.width = 100;
    newFrame.size.height = 100;
    [self.shimmeringView setFrame:newFrame];
    
    [self.shimmeringView addConstraint:[NSLayoutConstraint
                                      constraintWithItem:self.hoursShadowedLabel
                                      attribute:NSLayoutAttributeLeading
                                      relatedBy:NSLayoutRelationEqual
                                      toItem:self.shimmeringView
                                      attribute:NSLayoutAttributeTrailing
                                      multiplier: 1
                                      constant:10]];
    
    [self.shimmeringView addConstraint:[NSLayoutConstraint
                                      constraintWithItem:self.hoursVolunteeredLabel
                                      attribute:NSLayoutAttributeLeading
                                      relatedBy:NSLayoutRelationEqual
                                      toItem:self.shimmeringView
                                      attribute:NSLayoutAttributeTrailing
                                      multiplier: 1
                                      constant:10]];
    
    [self.shimmeringView addConstraint:[NSLayoutConstraint
                                      constraintWithItem:self.amountDonatedLabel
                                      attribute:NSLayoutAttributeLeading
                                      relatedBy:NSLayoutRelationEqual
                                      toItem:self.shimmeringView
                                      attribute:NSLayoutAttributeTrailing
                                      multiplier: 1
                                      constant:10]];
    
    [self.shimmeringView addConstraint:[NSLayoutConstraint
                                      constraintWithItem:self.usernameLabel
                                      attribute:NSLayoutAttributeLeading
                                      relatedBy:NSLayoutRelationEqual
                                      toItem:self.shimmeringView
                                      attribute:NSLayoutAttributeTrailing
                                      multiplier: 1
                                      constant:10]];
    
    [self.shimmeringView addConstraint:[NSLayoutConstraint
                                      constraintWithItem:self.tableView
                                      attribute:NSLayoutAttributeTop
                                      relatedBy:NSLayoutRelationEqual
                                      toItem:self.shimmeringView
                                      attribute:NSLayoutAttributeBottom
                                      multiplier: 1
                                      constant:50]];
    */
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

- (void)loadBasicProfile {
    // Setting username
    self.usernameLabel.text = PFUser.currentUser.username;
    
    // Querying for profile image
    PFQuery *query = [PFUser query];
    [query includeKey:@"image"];
    [query whereKey:@"objectId" equalTo:PFUser.currentUser.objectId];
    
    // Fetch posts asynchronously
    [query findObjectsInBackgroundWithBlock:^(NSArray *users, NSError *error) {
        if (users != nil) {
            // Create and store array of Post objects from retrieved posts
            PFUser *user = users[0];
            
            // Set profile image
            PFFileObject *image = user[@"image"];
            [self.profileImageView sd_setImageWithURL:[NSURL URLWithString:image.url]];
            self.shimmeringView.shimmering = NO;
        } else {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}

- (UIImage *)resizeImage:(UIImage *)image withSize:(CGSize)size {
    // Resizes an image to a specified size
    UIImageView *resizeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    
    resizeImageView.contentMode = UIViewContentModeScaleAspectFill;
    resizeImageView.image = image;
    
    UIGraphicsBeginImageContext(size);
    [resizeImageView.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    PastOpportunityCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"PastOpportunityCell"];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 10;
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

- (IBAction)didTapProfilePicture:(id)sender {
    // Setting up image picker controller
    UIImagePickerController *imagePickerVC = [UIImagePickerController new];
    imagePickerVC.delegate = self;
    imagePickerVC.allowsEditing = YES;
    imagePickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    // Present image picker controller
    [self presentViewController:imagePickerVC animated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    // Get the image captured by the UIImagePickerController and store it
    //UIImage *originalImage = info[UIImagePickerControllerOriginalImage];
    UIImage *editedImage = info[UIImagePickerControllerEditedImage];
    CGSize imageSize = CGSizeMake(300, 300);
    UIImage *resizedImage = [self resizeImage:editedImage withSize:imageSize];
    self.updatedProfileImage = resizedImage;
    
    [self saveImage];

    // Do something with the images (based on your use case)
    
    
    // Dismiss UIImagePickerController to go back to your original view controller
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveImage {
    // Save image to current user object
    PFUser *user = PFUser.currentUser;
    NSData *imageData = UIImagePNGRepresentation(self.updatedProfileImage);
    user[@"image"] = [PFFileObject fileObjectWithName:@"image.png" data:imageData contentType:@"image/png"];
    
    // Progress HUD while post is saved
    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
        // Update image in database
        [user saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
            if (succeeded) {
                // Display new profile image
                self.profileImageView.image = self.updatedProfileImage;
            } else {
                // Otherwise, displays an alert
                NSLog(@"Problem saving image: %@", error.localizedDescription);
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Error posting image." preferredStyle:(UIAlertControllerStyleAlert)];
                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
                [alert addAction:okAction];
                [self presentViewController:alert animated:YES completion:^{}];
            }
            
            // Adding a slight delay so progress HUD doesn't just flash
            [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(stopAnimation) userInfo:nil repeats:NO];
        }];
    });
}

- (void)stopAnimation {
    // Stopping progress HUD
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });
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
