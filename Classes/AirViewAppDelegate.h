//
//  AirViewAppDelegate.h
//  AirView
//
//  Created by Clément Vasseur on 12/18/10.
//  Copyright 2010 Clément Vasseur. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AirPlayController.h"
#import "ZZshowAndMonitorView.h"
@interface AirViewAppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow *window;
	AirPlayController *airplay;
    
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (strong,nonatomic)ZZshowAndMonitorView *showAndMonitorView;

@end
