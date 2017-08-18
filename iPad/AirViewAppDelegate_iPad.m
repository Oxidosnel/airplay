//
//  AirViewAppDelegate_iPad.m
//  AirView
//
//  Created by Clément Vasseur on 12/18/10.
//  Copyright 2010 Clément Vasseur. All rights reserved.
//

#import "AirViewAppDelegate_iPad.h"

@implementation AirViewAppDelegate_iPad


#pragma mark -
#pragma mark Application lifecycle

/**
 Superclass implementation saves changes in the application's managed object context before the application terminates.
 */
-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions{
    CGRect showFrame=CGRectMake(window.frame.origin.x, window.frame.origin.y+90, window.frame.size.width, window.frame.size.height-90);
    
    self.showAndMonitorView =[[[ZZshowAndMonitorView alloc] initWithFrame:showFrame] autorelease];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    self.showAndMonitorView.alpha=0;
  
    UIViewController *rootVc =[[UIViewController alloc] init];
    rootVc.view.backgroundColor = [UIColor grayColor];
    [rootVc.view addSubview:self.showAndMonitorView];
    
    
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
