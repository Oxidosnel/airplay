//
//  AirViewAppDelegate.m
//  AirView
//
//  Created by Clément Vasseur on 12/18/10.
//  Copyright 2010 Clément Vasseur. All rights reserved.
//

#import "DDLog.h"
#import "DDTTYLogger.h"
#import "DDASLLogger.h"

#import "AirViewAppDelegate.h"
#import "AirPlayController.h"
#import "DeviceInfo.h"
#import "GCDAsyncSocket.h"
// Log levels: off, error, warn, info, verbose
static const int ddLogLevel = LOG_LEVEL_VERBOSE;

@implementation AirViewAppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  
//这里没执行，被取代
	// Configure our logging framework.
	[DDLog addLogger:[DDTTYLogger sharedInstance]];
	[DDLog addLogger:[DDASLLogger sharedInstance]];
    
	// Override point for customization after application launch.
    
    _showAndMonitorView=[[ZZshowAndMonitorView alloc] initWithFrame:window.frame];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    _showAndMonitorView.alpha=0;
//    UIViewController *rootVc =[[UIViewController alloc] init];
//    rootVc.view.backgroundColor = [UIColor redColor];
//    window.rootViewController  =rootVc;
    //[rootVc.view addSubview:_showAndMonitorView];
    
	[window makeKeyAndVisible];
	return YES;
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
   	if (airplay == nil)
		airplay = [[AirPlayController alloc] initWithWindow:window];

	[airplay startServer];
    
        NSLog(@"airplay startServer");
    

}


- (void)applicationWillResignActive:(UIApplication *)application {
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
	[airplay stopPlayer];
	[airplay stopServer];
	//[airplay release];
	airplay = nil;
}


- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    /*
     Free up as much memory as possible by purging cached data objects that can be recreated (or reloaded from disk) later.
     */
	[airplay release];
	airplay = nil;
}


- (void)applicationWillTerminate:(UIApplication *)application {

	// Save data if appropriate.
}

- (void)dealloc {
    _showAndMonitorView=nil;
    [_showAndMonitorView release];
	[airplay release];
	[window release];
	[super dealloc];
}

@end
