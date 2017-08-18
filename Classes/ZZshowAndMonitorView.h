//
//  ZZshowAndMonitorView.h
//  AirView
//
//  Created by zxz zxz on 13-9-11.
//
//

#import <UIKit/UIKit.h>

@interface ZZshowAndMonitorView : UIView<UITableViewDataSource>{

    float offsetForStatusBar;
    UIColor *backColor;
}

@property (strong,nonatomic)UIImage *BigImg;





-(void)showImage:(UIImage *)img;
@end
