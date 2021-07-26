//
//  ComposeViewController.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/14/21.
//

#import "ComposeViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <SDWebImage/SDWebImage.h>
#import "FBShimmering.h"
#import "FBShimmeringView.h"
#import "FBShimmeringLayer.h"
#import <Parse/Parse.h>
@import UITextView_Placeholder;
#import "MBProgressHUD.h"
#import "QueryConstants.h"

@interface ComposeViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (strong, nonatomic) FBShimmeringView *shimmeringView;
@property (strong, nonatomic) NSNumber *rating;
@property (weak, nonatomic) IBOutlet UITextView *composeField;
@property (weak, nonatomic) IBOutlet UIButton *star1;
@property (weak, nonatomic) IBOutlet UIButton *star2;
@property (weak, nonatomic) IBOutlet UIButton *star3;
@property (weak, nonatomic) IBOutlet UIButton *star4;
@property (weak, nonatomic) IBOutlet UIButton *star5;

@end

@implementation ComposeViewController

#pragma mark - viewDidLoad()

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Placeholder shimmer while loading
    self.shimmeringView = [[FBShimmeringView alloc] initWithFrame:self.profileImageView.frame];
    self.shimmeringView.contentView = self.profileImageView;
    [self.view addSubview:self.shimmeringView];
    self.shimmeringView.shimmering = YES;
    
    // Rating defaults to 0, which is invalid
    self.rating = [NSNumber numberWithInt:0];
    
    [self styleElements];
    [self loadProfileImage];
}


#pragma mark - viewWillAppear()

- (void)viewWillAppear:(BOOL)animated {
    /*
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
     */
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    navigationBar.barTintColor = [UIColor colorNamed:@"navColor"];
    // self.tabBarController.tabBar.barTintColor = [UIColor colorNamed:@"navColor"];
}


#pragma mark - Load profile image

- (void)loadProfileImage {
    // Querying for profile image
    PFQuery *query = [PFUser query];
    [query includeKey:imageQuery];
    [query whereKey:objectIdKey equalTo:PFUser.currentUser.objectId];
    
    // Fetch posts asynchronously
    [query findObjectsInBackgroundWithBlock:^(NSArray *users, NSError *error) {
        if (users != nil) {
            // Create and store array of Post objects from retrieved posts
            PFUser *user = users[0];
            
            // Set profile image
            PFFileObject *image = user[imageQuery];
            self.profileImageView.alpha = 0;
            [self.profileImageView sd_setImageWithURL:[NSURL URLWithString:image.url] placeholderImage:nil options:SDWebImageRetryFailed completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                
                if (image) {
                    BOOL animated = NO;

                    if (cacheType == SDImageCacheTypeDisk || cacheType == SDImageCacheTypeNone) {
                        animated = YES;
                    }

                    self.profileImageView.image = image;

                    if (animated) {
                        [UIView animateWithDuration:1 animations:^{
                            self.profileImageView.alpha = 1.0;
                        }];

                    } else {
                        self.profileImageView.alpha = 1.0;
                    }
                }

            }];
            
            self.shimmeringView.shimmering = NO;
        } else {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}


#pragma mark - Compose actions

- (IBAction)didTapCancel:(id)sender {
    // Dismisses ComposeViewController
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didTapPost:(id)sender {
    if ([self.rating intValue] == 0) {
        // Present alert if user does not give a rating
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Please provide a star rating before posting your review" preferredStyle:(UIAlertControllerStyleAlert)];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
        [alert addAction:okAction];
        [self presentViewController:alert animated:YES completion:^{
        }];
    } else {
        // Setting post attributes for storage in database
        PFObject *review = [PFObject objectWithClassName:reviewClassName];
        review[commentQuery] = self.composeField.text;
        review[authorQuery] = PFUser.currentUser;
        review[starsQuery] = self.rating;
        review[forOrganizationWithIdQuery] = self.opportunity.author.organizationId;
        
        // Progress HUD while post is saved
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
            // Saving new post
            [review saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                if (succeeded) {
                    [self updateOrganizationStats];
                } else {
                    // Otherwise, displays an alert
                    NSLog(@"Problem posting review: %@", error.localizedDescription);
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Error posting image." preferredStyle:(UIAlertControllerStyleAlert)];
                    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {}];
                    [alert addAction:okAction];
                    [self presentViewController:alert animated:YES completion:^{}];
                }
            }];
        });
    }
}


#pragma mark - Update organization stats

- (void)updateOrganizationStats {
    PFQuery *query = [PFQuery queryWithClassName:organizationClassName];
    [query includeKey:totalScoreQuery];
    [query includeKey:numReviewsQuery];
    [query whereKey:objectIdKey equalTo:self.opportunity.author.organizationId];
    
    // Fetch asynchronously
    [query findObjectsInBackgroundWithBlock:^(NSArray *organizations, NSError *error) {
        if (organizations != nil) {
            PFObject *organization = organizations[0];
            
            // Update organization rating
            organization[totalScoreQuery] = [NSNumber numberWithInt:[organization[totalScoreQuery] intValue]+[self.rating intValue]];
            organization[numReviewsQuery] = [NSNumber numberWithInt:[organization[numReviewsQuery] intValue]+1];
            
            // Update stored organization rating
            self.opportunity.author.totalScore = [NSNumber numberWithInt:[self.opportunity.author.totalScore intValue]+[self.rating intValue]];
            self.opportunity.author.numReviews = [NSNumber numberWithInt:[self.opportunity.author.numReviews intValue]+1];
            
            // Update organization object
            [organization saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                if (succeeded) {
                    [self dismissViewControllerAnimated:YES completion:nil];
                    [self.delegate didPost];
                    
                    // Adding a slight delay so progress HUD doesn't just flash
                    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(stopAnimation) userInfo:nil repeats:NO];
                } else {
                    NSLog(@"Error: %@", error.localizedDescription);
                }
            }];
            
        } else {
            NSLog(@"%@", error.localizedDescription);
        }
    }];
}


#pragma mark - Detect star taps

- (IBAction)didTapStar1:(id)sender {
    [UIView transitionWithView:self.star1
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star1 setImage:[UIImage imageNamed:@"star-filled"] forState:UIControlStateNormal];
        }
        completion:nil];
    [UIView transitionWithView:self.star2
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star2 setImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
        }
        completion:nil];
    [UIView transitionWithView:self.star3
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star3 setImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
        }
        completion:nil];
    [UIView transitionWithView:self.star4
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star4 setImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
        }
        completion:nil];
    [UIView transitionWithView:self.star5
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star5 setImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
        }
        completion:nil];
    self.rating = [NSNumber numberWithInt:1];
}

- (IBAction)didTapStar2:(id)sender {
    [UIView transitionWithView:self.star1
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star1 setImage:[UIImage imageNamed:@"star-filled"] forState:UIControlStateNormal];
        }
        completion:nil];
    [UIView transitionWithView:self.star2
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star2 setImage:[UIImage imageNamed:@"star-filled"] forState:UIControlStateNormal];
        }
        completion:nil];
    [UIView transitionWithView:self.star3
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star3 setImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
        }
        completion:nil];
    [UIView transitionWithView:self.star4
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star4 setImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
        }
        completion:nil];
    [UIView transitionWithView:self.star5
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star5 setImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
        }
        completion:nil];
    self.rating = [NSNumber numberWithInt:2];
}

- (IBAction)didTapStar3:(id)sender {
    [UIView transitionWithView:self.star1
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star1 setImage:[UIImage imageNamed:@"star-filled"] forState:UIControlStateNormal];
        }
        completion:nil];
    [UIView transitionWithView:self.star2
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star2 setImage:[UIImage imageNamed:@"star-filled"] forState:UIControlStateNormal];
        }
        completion:nil];
    [UIView transitionWithView:self.star3
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star3 setImage:[UIImage imageNamed:@"star-filled"] forState:UIControlStateNormal];
        }
        completion:nil];
    [UIView transitionWithView:self.star4
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star4 setImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
        }
        completion:nil];
    [UIView transitionWithView:self.star5
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star5 setImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
        }
        completion:nil];
    self.rating = [NSNumber numberWithInt:3];
}

- (IBAction)didTapStar4:(id)sender {
    [UIView transitionWithView:self.star1
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star1 setImage:[UIImage imageNamed:@"star-filled"] forState:UIControlStateNormal];
        }
        completion:nil];
    [UIView transitionWithView:self.star2
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star2 setImage:[UIImage imageNamed:@"star-filled"] forState:UIControlStateNormal];
        }
        completion:nil];
    [UIView transitionWithView:self.star3
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star3 setImage:[UIImage imageNamed:@"star-filled"] forState:UIControlStateNormal];
        }
        completion:nil];
    [UIView transitionWithView:self.star4
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star4 setImage:[UIImage imageNamed:@"star-filled"] forState:UIControlStateNormal];
        }
        completion:nil];
    [UIView transitionWithView:self.star5
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star5 setImage:[UIImage imageNamed:@"star"] forState:UIControlStateNormal];
        }
        completion:nil];
    self.rating = [NSNumber numberWithInt:4];
}

- (IBAction)didTapStar5:(id)sender {
    [UIView transitionWithView:self.star1
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star1 setImage:[UIImage imageNamed:@"star-filled"] forState:UIControlStateNormal];
        }
        completion:nil];
    [UIView transitionWithView:self.star2
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star2 setImage:[UIImage imageNamed:@"star-filled"] forState:UIControlStateNormal];
        }
        completion:nil];
    [UIView transitionWithView:self.star3
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star3 setImage:[UIImage imageNamed:@"star-filled"] forState:UIControlStateNormal];
        }
        completion:nil];
    [UIView transitionWithView:self.star4
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star4 setImage:[UIImage imageNamed:@"star-filled"] forState:UIControlStateNormal];
        }
        completion:nil];
    [UIView transitionWithView:self.star5
        duration:0.3f
        options:UIViewAnimationOptionTransitionCrossDissolve
        animations:^{
        [self.star5 setImage:[UIImage imageNamed:@"star-filled"] forState:UIControlStateNormal];
        }
        completion:nil];
    self.rating = [NSNumber numberWithInt:5];
}


#pragma mark - Setup styling

- (void)styleElements {
    // Round profile images
    self.profileImageView.layer.cornerRadius = 25;
    
    // Round text view corners and border properties
    self.composeField.layer.cornerRadius = 10;
    self.composeField.layer.borderColor = [[UIColor systemGray3Color] CGColor];
    self.composeField.layer.borderWidth=1.0;
    
    // Text view placeholder text
    self.composeField.placeholder = @"Write a review...";
    self.composeField.placeholderColor = [UIColor lightGrayColor];
}


#pragma mark - Other functions

-(void)stopAnimation {
    // Stopping progress bar
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
    });
}

- (IBAction)dismissKeyboard:(id)sender {
    // Dismisses keyboard when screen is tapped
    [self.view endEditing:YES];
}


#pragma mark - UIColor from hex color

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
