//
//  ProfilePictureViewController.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/23/21.
//

#import "ProfilePictureViewController.h"
#import "UIImageView+AFNetworking.h"
#import <SDWebImage/SDWebImage.h>

@interface ProfilePictureViewController () <UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (nonatomic, assign) CGFloat lastScale;
@property (weak, nonatomic) IBOutlet UINavigationItem *navigationItem;

@end

@implementation ProfilePictureViewController

#pragma mark - viewDidLoad()

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Nav bar title
    self.navigationItem.title = self.opportunity.author.username;
    
    // Set organization profile picture
    [self.profileImageView sd_setImageWithURL:[NSURL URLWithString:self.opportunity.author.imageURL]];
    
    // Pinch gesture recognizer
    UIPinchGestureRecognizer *pgr = [[UIPinchGestureRecognizer alloc]
        initWithTarget:self action:@selector(handlePinchGesture:)];
    pgr.delegate = self;
    [self.profileImageView addGestureRecognizer:pgr];
    
    // Pan gesture recognizer
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    [panRecognizer setMinimumNumberOfTouches:1];
    [panRecognizer setMaximumNumberOfTouches:1];
    [self.profileImageView addGestureRecognizer:panRecognizer];
}


#pragma mark - Pinch to zoom

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)gestureRecognizer {
    
     if([gestureRecognizer state] == UIGestureRecognizerStateBegan) {
     // Reset the last scale
     self.lastScale = [gestureRecognizer scale];
     }

     if ([gestureRecognizer state] == UIGestureRecognizerStateBegan ||
     [gestureRecognizer state] == UIGestureRecognizerStateChanged) {

      CGFloat currentScale = [[[gestureRecognizer view].layer valueForKeyPath:@"transform.scale"] floatValue];

     // Constants to adjust the max/min values of zoom
     const CGFloat kMaxScale = 5.0;
     const CGFloat kMinScale = 1.0;

      CGFloat newScale = 1 -  (self.lastScale - [gestureRecognizer scale]);
      newScale = MIN(newScale, kMaxScale / currentScale);
      newScale = MAX(newScale, kMinScale / currentScale);
      CGAffineTransform transform = CGAffineTransformScale([[gestureRecognizer view] transform], newScale, newScale);
      [gestureRecognizer view].transform = transform;

      self.lastScale = [gestureRecognizer scale];
      }
}


#pragma mark - Pan image

- (void)pan:(UIPanGestureRecognizer *)gestureRecognizer {
    CGPoint translation = [gestureRecognizer translationInView:self.profileImageView];
    //CGPoint centerPoint = [gestureRecognizer locationInView:self.view];
    self.profileImageView.center = CGPointMake(self.profileImageView.center.x + translation.x, self.profileImageView.center.y + translation.y);
    [gestureRecognizer setTranslation:CGPointZero inView:self.profileImageView];
    /*
    self.profileImageView.center = [gestureRecognizer locationInView:self.profileImageView.superview];
     */
}

#pragma mark - Dismiss view controller

- (IBAction)didTapExit:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
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
