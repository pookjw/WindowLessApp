//
//  AppDelegate.m
//  MyApp
//
//  Created by Jinwoo Kim on 7/27/25.
//

#import "AppDelegate.h"
#import "SceneDelegate.h"
#import "LayerSceneDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    UISceneConfiguration *configuration = [connectingSceneSession.configuration copy];
    
    NSUserActivity *userActivity = options.userActivities.allObjects.firstObject;
    if ([userActivity.activityType isEqualToString:@"LayerScene"]) {
        configuration.delegateClass = [LayerSceneDelegate class];
    } else {
        configuration.delegateClass = [SceneDelegate class];
        configuration.storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:NSBundle.mainBundle];
    }
    
    return [configuration autorelease];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
