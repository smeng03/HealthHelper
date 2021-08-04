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
#import "QueryConstants.h"
#import "Notification.h"

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
@property (weak, nonatomic) IBOutlet UIView *notificationView;
@property (weak, nonatomic) IBOutlet UILabel *notificationLabel;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;

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
    [self notificationSetup];
    
}


#pragma mark - viewWillAppear()

- (void)viewWillAppear:(BOOL)animated {
    
    // Loads in user-picked color
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *navColor = [defaults objectForKey:@"nav_color"];
    
    // Set bar color
    self.navigationBar.barTintColor = [UIColor colorNamed:navColor];
    
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
        
        // Return back to previous view controller
        [self dismissViewControllerAnimated:YES completion:nil];
        
        // Setting post attributes for storage in database
        PFObject *review = [PFObject objectWithClassName:reviewClassName];
        review[commentQuery] = self.composeField.text;
        review[authorQuery] = PFUser.currentUser;
        review[starsQuery] = self.rating;
        review[forOrganizationWithIdQuery] = self.opportunity.author.organizationId;
        
        // Save review in background
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            // Saving new post
            [review saveInBackgroundWithBlock:^(BOOL succeeded, NSError * error) {
                if (succeeded) {
                    
                    [self updateOrganizationStats];
                    
                } else {
                    
                    // Broadcast that review saving has failed
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReviewFailed" object:nil userInfo:nil];
                    
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
                    
                    // Broadcast that review saving is complete
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReviewPosted" object:nil userInfo:nil];
                    [self.delegate didPost];
            
                } else {
                    
                    // Broadcast that review saving has failed
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReviewFailed" object:nil userInfo:nil];
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


#pragma mark - Setup styling

- (void)styleElements {
    
    // Round profile images
    self.profileImageView.layer.cornerRadius = 25;
    
    // Round text view corners, border properties, and shadow
    self.composeField.layer.cornerRadius = 10;
    self.composeField.layer.borderColor = [[UIColor systemGray3Color] CGColor];
    self.composeField.layer.borderWidth= 1.0;
    self.composeField.layer.shadowOffset = CGSizeMake(0, 0);
    self.composeField.layer.shadowRadius = 5;
    self.composeField.layer.shadowOpacity = 0.25;
    
    // Text view placeholder text
    self.composeField.placeholder = @"Write a review...";
    self.composeField.placeholderColor = [UIColor lightGrayColor];
    
}


#pragma mark - Other functions

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
