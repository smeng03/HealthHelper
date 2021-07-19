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
#import "Opportunity.h"
#import "DetailsViewController.h"

@interface ProfileViewController () <UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *usernameLabel;
@property (weak, nonatomic) IBOutlet UILabel *hoursVolunteeredLabel;
@property (weak, nonatomic) IBOutlet UILabel *amountDonatedLabel;
@property (weak, nonatomic) IBOutlet UILabel *hoursShadowedLabel;
@property (strong, nonatomic) UIImage *updatedProfileImage;
@property (strong, nonatomic) PFUser *user;
@property (strong, nonatomic) FBShimmeringView *shimmeringView;
@property (strong, nonatomic) NSMutableArray *opportunities;
@property (strong, nonatomic) NSMutableArray *filteredOpportunities;
@property (strong, nonatomic) NSArray *pastOpportunities;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (strong, nonatomic) UIRefreshControl *refreshControl;

@end

@implementation ProfileViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Table view data source and delegate
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [UIView new];
    
    // Search bar delegate
    self.searchBar.delegate = self;
    
    // Loading basic profile information
    [self loadBasicProfile];
    
    // Loading past opportunities
    [self loadPastOpportunityArray];
    
    // Round profile images
    self.profileImageView.layer.cornerRadius = 50;
    
    // Search bar placeholder text
    self.searchBar.placeholder = @"Search your opportunities...";
    
    // Refresh Control
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(loadPastOpportunityArray) forControlEvents:UIControlEventValueChanged];
    
    // Places refresher at correct location
    [self.tableView insertSubview:self.refreshControl atIndex:0];
    
    // Placeholder shimmer while loading
    // self.profileImageView.image = [SDAnimatedImage imageNamed:@"loading_square.gif"];
    self.shimmeringView = [[FBShimmeringView alloc] initWithFrame:self.profileImageView.frame];
    self.shimmeringView.contentView = self.profileImageView;
    [self.view addSubview:self.shimmeringView];
    self.shimmeringView.shimmering = YES;
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
    
    // Load info again
    [self loadBasicProfile];
    [self loadPastOpportunityArray];
}

- (void)loadPastOpportunityArray {
    // Query for opportunities array
    PFQuery *queryUser = [PFUser query];
    [queryUser includeKey:@"pastOpportunities"];
    [queryUser whereKey:@"objectId" equalTo:PFUser.currentUser.objectId];
    
    // Fetch user asynchronously
    [queryUser findObjectsInBackgroundWithBlock:^(NSArray *users, NSError *error) {
        if (users != nil) {
            // Create and store array of Post objects from retrieved posts
            PFUser *user = users[0];
            self.pastOpportunities = user[@"pastOpportunities"];
            [self loadPastOpportunities];
        } else {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}

- (void)loadPastOpportunities {
    // Construct query for opportunities
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
    [query includeKey:@"donationAmount"];
    [query includeKey:@"hours"];
    [query includeKey:@"date"];
    [query includeKey:@"position"];
    query.limit = 20;
    [query orderByDescending:@"createdAt"];
    [query whereKey:@"objectId" containedIn:self.pastOpportunities];
    
    // Fetch posts asynchronously
    [query findObjectsInBackgroundWithBlock:^(NSArray *opportunities, NSError *error) {
        if (opportunities != nil) {
            // Create and store array of Opportunity objects from retrieved posts
            self.opportunities = [Opportunity createOpportunityArray:opportunities];
            self.filteredOpportunities = self.opportunities;
            
            [self.tableView reloadData];
            [self.refreshControl endRefreshing];
        } else {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}

- (void)loadBasicProfile {
    // Setting username
    self.usernameLabel.text = PFUser.currentUser.username;
    
    // Querying for profile image
    PFQuery *query = [PFUser query];
    [query includeKey:@"image"];
    [query includeKey:@"amountDonated"];
    [query includeKey:@"hoursVolunteered"];
    [query includeKey:@"hoursShadowed"];
    [query whereKey:@"objectId" equalTo:PFUser.currentUser.objectId];
    
    // Fetch user asynchronously
    [query findObjectsInBackgroundWithBlock:^(NSArray *users, NSError *error) {
        if (users != nil) {
            // Create and store array of Post objects from retrieved posts
            PFUser *user = users[0];
            
            // Set profile image
            PFFileObject *image = user[@"image"];
            [self.profileImageView sd_setImageWithURL:[NSURL URLWithString:image.url]];
            self.shimmeringView.shimmering = NO;
            
            // Set user sats
            self.hoursVolunteeredLabel.text = [NSString stringWithFormat:@"Hours volunteered: %@", user[@"hoursVolunteered"]];
            self.amountDonatedLabel.text = [NSString stringWithFormat:@"Amount donated: $%@", user[@"amountDonated"]];
            self.hoursShadowedLabel.text = [NSString stringWithFormat:@"Hours shadowed: %@", user[@"hoursShadowed"]];
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
    
    // Setting cell and style
    [cell setCell:self.filteredOpportunities[indexPath.row]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.filteredOpportunities.count;
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
    
    // If user has a camera, they can choose between camera roll or camera
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        // Choose between picking a picture or using camera
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Open camera or camera roll?" message:@"Do you want to choose a photo from your camera roll or take a new picture?" preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *cameraRollAction = [UIAlertAction actionWithTitle:@"Open camera roll" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            imagePickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            // Present image picker controller
            [self presentViewController:imagePickerVC animated:YES completion:nil];
        }];
        UIAlertAction *cameraAction = [UIAlertAction actionWithTitle:@"Take a photo" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            imagePickerVC.sourceType = UIImagePickerControllerSourceTypeCamera;
            // Present image picker controller
            [self presentViewController:imagePickerVC animated:YES completion:nil];
        }];
        [alert addAction:cameraRollAction];
        [alert addAction:cameraAction];
        [self presentViewController:alert animated:YES completion:^{
        }];
    } else {
        // If user does not have camera, they can only chooe from camera roll
        imagePickerVC.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        // Present image picker controller
        [self presentViewController:imagePickerVC animated:YES completion:nil];
    }
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

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    if (searchText.length != 0) {
        // Searches for objects containing what the user types
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(author.username CONTAINS[cd] %@)", searchText];
        
        // Filters opportunities based on criteria
        self.filteredOpportunities = [(NSArray *)[self.opportunities filteredArrayUsingPredicate:predicate] mutableCopy];
    }
    else {
        self.filteredOpportunities = self.opportunities;
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
    self.searchBar.text = @"";
    [self.searchBar resignFirstResponder];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Identify tapped cell and get associated opportunity
    UITableViewCell *tappedCell = sender;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:tappedCell];
    Opportunity *opportunity = self.filteredOpportunities[indexPath.row];
    
    // Send information
    DetailsViewController *detailsViewController = [segue destinationViewController];
    detailsViewController.opportunity = opportunity;
}

@end
