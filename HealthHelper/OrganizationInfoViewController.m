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

@interface OrganizationInfoViewController () <UITableViewDelegate, UITableViewDataSource, ComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIImageView *profileImageView;
@property (weak, nonatomic) IBOutlet UILabel *organizationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *reviewButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *reviews;
@property (weak, nonatomic) IBOutlet UILabel *reviewCountLabel;

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
}

#pragma mark - viewWillApear()

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
    self.tabBarController.tabBar.barTintColor = [UIColor colorNamed:@"navColor"];
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
            self.reviewCountLabel.text = [NSString stringWithFormat:@"Reviews (%lu)", (unsigned long)self.reviews.count];
            
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
    [cell setCell:self.reviews[indexPath.row]];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.reviews.count;
}


#pragma mark - Open full profile picture

- (IBAction)didTapProfilePicture:(id)sender {
    [self performSegueWithIdentifier:@"toFullProfileView" sender:nil];
}



#pragma mark - didPost() delegate method

- (void)didPost {
    [self loadReviews];
}


#pragma mark - Setup styling

- (void)styleElements {
    // Nav bar title
    self.navigationItem.title = self.opportunity.author.username;
    
    // Rounded profile images
    self.profileImageView.layer.cornerRadius = 50;
    
    // Rounded corners on button
    self.reviewButton.layer.cornerRadius = 5;
}

- (void)setData {
    // Set organization name
    self.organizationNameLabel.text = self.opportunity.author.username;
    
    // Set organization decription
    self.descriptionLabel.text = self.opportunity.author.text;
    
    // Set organization profile picture
    [self.profileImageView sd_setImageWithURL:[NSURL URLWithString:self.opportunity.author.imageURL]];
}


#pragma mark - UI Color from hex

-(UIColor *)colorWithHex:(UInt32)col {
    unsigned char r, g, b;
    b = col & 0xFF;
    g = (col >> 8) & 0xFF;
    r = (col >> 16) & 0xFF;
    return [UIColor colorWithRed:(float)r/255.0f green:(float)g/255.0f blue:(float)b/255.0f alpha:1];
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
