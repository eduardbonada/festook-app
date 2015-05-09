//
//  AppDelegate.m
//  Festook
//
//  Created by Eduard Bonada Cruells on 12/03/15.
//  Copyright (c) 2015 ebc. All rights reserved.
//

#import "AppDelegate.h"

#import "Flurry.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Flurry setup
    [Flurry setLogLevel:FlurryLogLevelNone];
    [Flurry startSession:@"PVBDRP4HVJGR8VKMKZBN"];
    
    // configuration of the page control appearance
    UIPageControl *pageControl = [UIPageControl appearance];
    pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
    pageControl.currentPageIndicatorTintColor = [UIColor darkGrayColor];
    pageControl.backgroundColor = [UIColor clearColor];
    
    // copy initial files to application support directory
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *applicationSupportDirectory = [paths objectAtIndex:0];
    NSArray* fileNames = @[@"listFestivals.txt",@"ps2015_echonestDB10_bandDistance.txt",@"ps2015_listBands.txt"];
    for(NSString* fileName in fileNames){
        NSString *appSupportFilePath = [applicationSupportDirectory stringByAppendingPathComponent:fileName];
        if ([fileManager fileExistsAtPath:appSupportFilePath] == NO) {
            NSString *initialFilePath = [[NSBundle mainBundle] pathForResource:[fileName componentsSeparatedByString:@"."][0]  ofType:@"txt"];
            [fileManager copyItemAtPath:initialFilePath toPath:appSupportFilePath error:&error];
        }
    }
    
    return YES;
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
    // Manages a received notification while the app is open
    UIApplicationState state = [application applicationState];
    if (state == UIApplicationStateInactive) {
        // Application was in the background when notification was delivered.
    } else {
        /*
         UIAlertController *alertController = [UIAlertController
         alertControllerWithTitle:@"Notification Received"
         message:notification.alertBody
         preferredStyle:UIAlertControllerStyleAlert];
         UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
         style:UIAlertActionStyleDefault
         handler:^(UIAlertAction *action){}];
         [alertController addAction:okAction];
         [self.window.rootViewController presentViewController:alertController animated:YES completion:nil];
         */
        
        UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"Festook"
                                                           message:notification.alertBody
                                                          delegate:nil
                                                 cancelButtonTitle:@"OK"
                                                 otherButtonTitles:nil, nil];
        [alertView show];
    }
    
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
