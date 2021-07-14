//
//  OrganizationInfoViewController.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/14/21.
//

#import "OrganizationInfoViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface OrganizationInfoViewController ()
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;

@end

@implementation OrganizationInfoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Rounded profile images
    self.profileImageView.layer.cornerRadius = 50;
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
