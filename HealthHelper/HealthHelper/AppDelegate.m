//
//  AppDelegate.m
//  HealthHelper
//
//  Created by Sabrina P Meng on 7/12/21.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>
@import GoogleMaps;
@import GooglePlaces;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    ParseClientConfiguration *configuration = [ParseClientConfiguration configurationWithBlock:^(id<ParseMutableClientConfiguration> configuration) {
      NSString *path = [[NSBundle mainBundle] pathForResource: @"Keys" ofType: @"plist"];
      NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile: path];
         
      configuration.applicationId= [dict objectForKey: @"applicationID"];
      configuration.clientKey = [dict objectForKey: @"clientKey"];
      configuration.server = @"https://parseapi.back4app.com/";
      [GMSServices provideAPIKey:[dict objectForKey: @"mapsAPIKey"]];
      [GMSPlacesClient provideAPIKey:[dict objectForKey: @"mapsAPIKey"]];
    }];
    [Parse initializeWithConfiguration:configuration];
    
    // Changing appearance of UI elements
    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize:12.0]} forState:UIControlStateNormal];
    [[UISegmentedControl appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor blackColor]} forState:UIControlStateSelected];
    [[UISegmentedControl appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor whiteColor]} forState:UIControlStateNormal];
    
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
