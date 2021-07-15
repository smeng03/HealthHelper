//
//  OrganizationInfoViewController.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/14/21.
//

#import "OrganizationInfoViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <SDWebImage/SDWebImage.h>
#import "ComposeViewController.h"

@interface OrganizationInfoViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *organizationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@end

@implementation OrganizationInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Nav bar title
    self.navigationItem.title = self.opportunity.author.username;
    
    // Rounded profile images
    self.profileImageView.layer.cornerRadius = 50;
    
    // Set organization name
    self.organizationNameLabel.text = self.opportunity.author.username;
    
    // Set organization decription
    self.descriptionLabel.text = self.opportunity.author.text;
    
    // Set organization profile picture
    [self.profileImageView sd_setImageWithURL:[NSURL URLWithString:self.opportunity.author.imageURL]];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqual:@"composeSegue"]) {
        // Sending current opportunity to next view controller
        ComposeViewController *composeViewController = [segue destinationViewController];
        composeViewController.opportunity = self.opportunity;
    }
}

@end
