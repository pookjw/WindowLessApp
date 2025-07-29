//
//  ViewController.m
//  MyApp
//
//  Created by Jinwoo Kim on 7/27/25.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)buttonDidTrigger:(UIButton *)sender {
    UISceneSessionActivationRequest *request = [UISceneSessionActivationRequest request];
    NSUserActivity *userActivity = [[NSUserActivity alloc] initWithActivityType:@"LayerScene"];
    request.userActivity = userActivity;
    [userActivity release];
    [UIApplication.sharedApplication activateSceneSessionForRequest:request errorHandler:^(NSError * _Nonnull error) {
        NSLog(@"%@", error);
    }];
}

@end
