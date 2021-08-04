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
#import "Review.h"
#import "ReviewCell.h"
#import "QueryConstants.h"
#import "ProfilePictureViewController.h"
#import "Notification.h"

@interface OrganizationInfoViewController () <UITableViewDelegate, UITableViewDataSource, ComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *organizationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *reviewButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *reviews;
@property (weak, nonatomic) IBOutlet UILabel *reviewCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *ratingLabel;
@property (weak, nonatomic) IBOutlet UIView *notificationView;
@property (weak, nonatomic) IBOutlet UILabel *notificationLabel;
@property (strong, nonatomic) NSMutableArray *filteredReviews;
@property (weak, nonatomic) IBOutlet UIButton *starButton1;
@property (weak, nonatomic) IBOutlet UIButton *starButton2;
@property (weak, nonatomic) IBOutlet UIButton *starButton3;
@property (weak, nonatomic) IBOutlet UIButton *starButton4;
@property (weak, nonatomic) IBOutlet UIButton *starButton5;
@property (nonatomic, assign) BOOL star1On;
@property (nonatomic, assign) BOOL star2On;
@property (nonatomic, assign) BOOL star3On;
@property (nonatomic, assign) BOOL star4On;
@property (nonatomic, assign) BOOL star5On;

@end

@implementation OrganizationInfoViewController

#pragma mark - viewDidLoad()

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    // Delegates and data sources
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    // Load reviews for organization
    [self loadReviews];
    
    [self styleElements];
    [self setData];
    [self notificationSetup];
    
}

#pragma mark - viewWillAppear()

- (void)viewWillAppear:(BOOL)animated {
    
    // Loads in user-picked color
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *navColor = [defaults objectForKey:@"nav_color"];
    
    // Set bar color
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    navigationBar.barTintColor = [UIColor colorNamed:navColor];
    self.tabBarController.tabBar.barTintColor = [UIColor colorNamed:navColor];
    
}


#pragma mark - Load reviews from database

- (void)loadReviews {
    
    // Construct query
    PFQuery *query = [PFQuery queryWithClassName:reviewClassName];
    [query includeKey:commentQuery];
    [query includeKey:starsQuery];
    [query includeKey:authorQuery];
    [query whereKey:forOrganizationWithIdQuery equalTo:self.opportunity.author.organizationId];
    query.limit = 20;
    [query orderByDescending:createdAtQuery];
    
    // Fetch posts asynchronously
    [query findObjectsInBackgroundWithBlock:^(NSArray *reviews, NSError *error) {
        if (reviews != nil) {
            
            // Create and store array of Opportunity objects from retrieved posts
            self.reviews = [Review createReviewArray:reviews];
            self.filteredReviews = self.reviews;
            self.reviewCountLabel.text = [NSString stringWithFormat:@"Reviews (%lu)", (unsigned long)self.filteredReviews.count];
            
            [self.tableView reloadData];
            
        } else {
            
            NSLog(@"%@", error.localizedDescription);
            
        }
    }];
}


#pragma mark - Table View

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    
    ReviewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ReviewCell"];
    
    // Setting cell and style
    [cell setCell:self.filteredReviews[indexPath.row]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
    
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.filteredReviews.count;
    
}


#pragma mark - Star filtering

- (void)filterStars:(NSNumber *)starCount {
    
    if ([starCount intValue] == 0) {
        
        self.filteredReviews = self.reviews;
        
    } else {
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(stars == %@)", starCount];
        
        NSArray *filteredData = [self.reviews filteredArrayUsingPredicate:predicate];
        
        self.filteredReviews = [filteredData mutableCopy];
        
    }
    
    self.reviewCountLabel.text = [NSString stringWithFormat:@"Reviews (%lu)", (unsigned long)self.filteredReviews.count];
    [self.tableView reloadData];
    
}

- (IBAction)didTapStar1:(id)sender {
    
    if (self.star1On) {
        
        self.star1On = !self.star1On;
        [self filterStars:@0];
        [self toggleOff:self.starButton1];
        
    } else {
        
        [self clearButtons];
        self.star1On = !self.star1On;
        [self filterStars:@1];
        [self toggleOn:self.starButton1];
        
    }
    
}

- (IBAction)didTapStar2:(id)sender {
    
    if (self.star2On) {
        
        self.star2On = !self.star2On;
        [self filterStars:@0];
        [self toggleOff:self.starButton2];
        
    } else {
        
        [self clearButtons];
        self.star2On = !self.star2On;
        [self filterStars:@2];
        [self toggleOn:self.starButton2];
        
    }
    
}

- (IBAction)didTapStar3:(id)sender {
    
    if (self.star3On) {
        
        self.star3On = !self.star3On;
        [self filterStars:@0];
        [self toggleOff:self.starButton3];
        
    } else {
        
        [self clearButtons];
        self.star3On = !self.star3On;
        [self filterStars:@3];
        [self toggleOn:self.starButton3];
        
    }
    
}

- (IBAction)didTapStar4:(id)sender {
    
    if (self.star4On) {
        
        self.star4On = !self.star4On;
        [self filterStars:@0];
        [self toggleOff:self.starButton4];
        
    } else {
        
        [self clearButtons];
        self.star4On = !self.star4On;
        [self filterStars:@4];
        [self toggleOn:self.starButton4];
        
    }
    
}

- (IBAction)didTapStar5:(id)sender {
    
    if (self.star5On) {
        
        self.star5On = !self.star5On;
        [self filterStars:@0];
        [self toggleOff:self.starButton5];
        
    } else {
        
        [self clearButtons];
        self.star5On = !self.star5On;
        [self filterStars:@5];
        [self toggleOn:self.starButton5];
        
    }
    
}

- (void)clearButtons {
    
    NSArray *buttons = @[self.starButton1, self.starButton2, self.starButton3, self.starButton4, self.starButton5];
    
    for (UIButton *button in buttons) {
        
        self.star1On = self.star2On = self.star3On = self.star4On = self.star5On = FALSE;
        [self toggleOff:button];
        
    }
    
}

- (void)toggleOff:(UIButton *)button {
    
    button.backgroundColor = [UIColor colorWithRed:73/255.0 green:93/255.0 blue:1 alpha:1];
    button.layer.shadowOpacity = 0.25;
    
}

- (void)toggleOn:(UIButton *)button {
    
    button.backgroundColor = [UIColor colorWithRed:47/255.0 green:59/255.0 blue:161/255.0 alpha:1];
    button.layer.shadowOpacity = 0;
    
}


#pragma mark - Open full profile picture

- (IBAction)didTapProfilePicture:(id)sender {
    
    [self performSegueWithIdentifier:@"toFullProfileView" sender:nil];
    
}



#pragma mark - didPost() delegate method

- (void)didPost {
    
    [self loadReviews];
    
    // Resetting rating label
    if ([self.opportunity.author.numReviews intValue] == 0) {
        self.ratingLabel.text = @"No ratings yet";
    } else {
        self.ratingLabel.text = [NSString stringWithFormat:@"Average rating: %.1f/5.0", [self.opportunity.author.totalScore floatValue]/[self.opportunity.author.numReviews floatValue]];
    }
    
}


#pragma mark - Setup styling
- (void)styleElements {
    
    // Nav bar title
    self.navigationItem.title = self.opportunity.author.username;
    
    // Rounded profile images
    self.profileImageView.layer.cornerRadius = 50;
    
    // Rounded corners on button and shadow
    self.reviewButton.layer.cornerRadius = 5;
    self.reviewButton.layer.shadowOffset = CGSizeMake(0, 0);
    self.reviewButton.layer.shadowRadius = 3;
    self.reviewButton.layer.shadowOpacity = 0.25;
    
    [self styleButtons];
    
}

- (void)styleButtons {
    
    NSArray *buttons = @[self.starButton1, self.starButton2, self.starButton3, self.starButton4, self.starButton5];
    
    for (UIButton *button in buttons) {
        button.layer.cornerRadius = 15;
        button.backgroundColor = [UIColor colorWithRed:73/255.0 green:93/255.0 blue:1 alpha:1];
        button.layer.shadowOffset = CGSizeMake(0, 0);
        button.layer.shadowRadius = 3;
        button.layer.shadowOpacity = 0.25;
    }
    
}

- (void)setData {
    
    // Set organization name
    self.organizationNameLabel.text = self.opportunity.author.username;
    
    // Set organization decription
    self.descriptionLabel.text = self.opportunity.author.text;
    
    // Set organization profile picture
    self.profileImageView.alpha = 0;
    [self.profileImageView sd_setImageWithURL:[NSURL URLWithString:self.opportunity.author.imageURL] placeholderImage:nil options:SDWebImageRetryFailed completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
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
    
    // Setting rating label
    if ([self.opportunity.author.numReviews intValue] == 0) {
        self.ratingLabel.text = @"No ratings yet";
    } else {
        self.ratingLabel.text = [NSString stringWithFormat:@"Average rating: %.1f/5.0", [self.opportunity.author.totalScore floatValue]/[self.opportunity.author.numReviews floatValue]];
    }
    
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


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqual:@"composeSegue"]) {
        
        // Sending current opportunity to next view controller
        ComposeViewController *composeViewController = [segue destinationViewController];
        composeViewController.opportunity = self.opportunity;
        composeViewController.delegate = self;
        
    } else if ([segue.identifier isEqual:@"toFullProfileView"]) {
        
        ProfilePictureViewController *profilePictureViewController = [segue destinationViewController];
        profilePictureViewController.opportunity = self.opportunity;
        
    }
    
}

@end
