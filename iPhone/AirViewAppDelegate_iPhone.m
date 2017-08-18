//
//  AirViewAppDelegate_iPhone.m
//  AirView
//
//  Created by Clément Vasseur on 12/18/10.
//  Copyright 2010 Clément Vasseur. All rights reserved.
//

#import "AirViewAppDelegate_iPhone.h"

#import "RTSPClient.h"
@implementation AirViewAppDelegate_iPhone

#pragma mark -
#pragma mark Application lifecycle

/**
 Superclass implementation saves changes in the application's managed object context before the application terminates.
 */
-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    //[super application:application didFinishLaunchingWithOptions:launchOptions];
        CGRect showFrame=CGRectMake(window.frame.origin.x, window.frame.origin.y+50, window.frame.size.width, window.frame.size.height-50);
   
    self.showAndMonitorView =[[[ZZshowAndMonitorView alloc] initWithFrame:showFrame] autorelease];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    self.showAndMonitorView.alpha=0;
    UIViewController *rootVc =[[UIViewController alloc] init];
    rootVc.view.backgroundColor = [UIColor redColor];
    [rootVc.view addSubview:self.showAndMonitorView];
    
    
//    RTSPClient *RTSPVC= [[RTSPClient alloc] init];
//
//    window.rootViewController  =RTSPVC;
     window.rootViewController  =rootVc;
    [window makeKeyAndVisible];
    return YES;
}
- (void)applicationWillTerminate:(UIApplication *)application {
	[super applicationWillTerminate:application];
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
	[super dealloc];
}


@end
