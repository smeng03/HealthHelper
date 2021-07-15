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

@interface ComposeViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (strong, nonatomic) FBShimmeringView *shimmeringView;
@property (weak, nonatomic) IBOutlet UITextView *composeField;
@property (weak, nonatomic) IBOutlet UIImageView *star1;
@property (weak, nonatomic) IBOutlet UIImageView *star2;
@property (weak, nonatomic) IBOutlet UIImageView *star3;
@property (weak, nonatomic) IBOutlet UIImageView *star4;
@property (weak, nonatomic) IBOutlet UIImageView *star5;

@end

@implementation ComposeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Round profile images
    self.profileImageView.layer.cornerRadius = 25;
    
    // Round text view corners and border properties
    self.composeField.layer.cornerRadius = 10;
    self.composeField.layer.borderColor = [[UIColor systemGray3Color] CGColor];
    self.composeField.layer.borderWidth=1.0;
    
    // Placeholder shimmer while loading
    self.shimmeringView = [[FBShimmeringView alloc] initWithFrame:self.profileImageView.frame];
    self.shimmeringView.contentView = self.profileImageView;
    [self.view addSubview:self.shimmeringView];
    self.shimmeringView.shimmering = YES;
    
    [self loadProfileImage];
    

}

- (void)loadProfileImage {
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

- (IBAction)didTapCancel:(id)sender {
    // Dismisses ComposeViewController
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didTapPost:(id)sender {
}

- (IBAction)didTapStar1:(id)sender {
}

- (IBAction)didTapStar2:(id)sender {
}

- (IBAction)didTapStar3:(id)sender {
}

- (IBAction)didTapStar4:(id)sender {
}

- (IBAction)didTapStar5:(id)sender {
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
