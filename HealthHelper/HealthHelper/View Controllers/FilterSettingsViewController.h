//
//  FilterSettingsViewController.h
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/21/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FilterSettingsControllerDelegate

- (void)didUpdateDistance:(int)sortType;

@end

@interface FilterSettingsViewController : UIViewController

@property (nonatomic, weak) id<FilterSettingsControllerDelegate> delegate;
@property (nonatomic, strong) NSString *units;

@end

NS_ASSUME_NONNULL_END
