//
//  AdView_IpadController.h
//  AirView
//
//  Created by zxz zxz on 13-9-11.
//
//

#import <UIKit/UIKit.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

@class GADBannerView, GADRequest;
@interface AdView_IpadController : UIViewController<GADBannerViewDelegate>{


    GADBannerView *adBanner_;;
}
@property (nonatomic, retain) GADBannerView *adBanner;
@end
