//
//  AdView_IphoneController.m
//  AirView
//
//  Created by zxz zxz on 13-9-11.
//
//

#import "AdView_IphoneController.h"


#import "UIColor+iOS7Colors.h"
@interface AdView_IphoneController ()

@end

@implementation AdView_IphoneController
@synthesize adBanner = adBanner_;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)randomBackColor{
    NSArray *colorArray = @[[UIColor iOS7redColor],[UIColor iOS7orangeColor],[UIColor iOS7yellowColor],[UIColor iOS7greenColor],[UIColor iOS7lightBlueColor],[UIColor iOS7darkBlueColor],[UIColor iOS7purpleColor],[UIColor iOS7pinkColor],[UIColor iOS7darkGrayColor],[UIColor iOS7lightGrayColor]];
    
    self.view.backgroundColor=[colorArray objectAtIndex:arc4random()%[colorArray count]];
}
-(void)viewWillAppear:(BOOL)animated{
    
    [self.view setFrame:CGRectMake(0, 0, kGADAdSizeBanner.size.width, kGADAdSizeBanner.size.height)];
    [self.adBanner setFrame:CGRectMake(0, 0, kGADAdSizeBanner.size.width, kGADAdSizeBanner.size.height)];
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self randomBackColor];
    CGPoint origin = CGPointMake(0,0);
	// Do any additional setup after loading the view.
    self.adBanner = [[[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner origin:origin] autorelease];
    // Specify the ad's "unit identifier". This is your AdMob Publisher ID.
    self.adBanner.adUnitID = @"a152318a6b88483";
    self.adBanner.delegate = self;
    // Let the runtime know which UIViewController to restore after taking
    // the user wherever the ad goes and add it to the view hierarchy.
    self.adBanner.rootViewController = self;
    [self.view addSubview:self.adBanner];
    
    // Initiate a generic request to load it with an ad.
    
    self.adBanner.center =
    CGPointMake(self.view.center.x, self.adBanner.center.y);
    [self.adBanner loadRequest:[self createRequest]];

    
}
#pragma mark GADRequest generation

// Here we're creating a simple GADRequest and whitelisting the application
// for test ads. You should request test ads during development to avoid
// generating invalid impressions and clicks.
- (GADRequest *)createRequest {
    GADRequest *request = [GADRequest request];
    
    // Make the request for a test ad. Put in an identifier for the simulator as
    // well as any devices you want to receive test ads.
    request.testDevices =
    [NSArray arrayWithObjects:
     // TODO: Add your device/simulator test identifiers here. They are
     // printed to the console when the app is launched.
     nil];
    return request;
}
#pragma mark GADBannerViewDelegate impl

// We've received an ad successfully.
- (void)adViewDidReceiveAd:(GADBannerView *)adView {
    NSLog(@"Received ad successfully");
}

- (void)adView:(GADBannerView *)view
didFailToReceiveAdWithError:(GADRequestError *)error {
    NSLog(@"Failed to receive ad with error: %@", [error localizedFailureReason]);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)dealloc{
    adBanner_.delegate = nil;
    [adBanner_ release];
    [super dealloc];
}

@end
