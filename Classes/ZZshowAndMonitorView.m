//
//  ZZshowAndMonitorView.m
//  AirView
//
//  Created by zxz zxz on 13-9-11.
//
//
#import "UIColor+iOS7Colors.h"
#import "ZZshowAndMonitorView.h"

@implementation ZZshowAndMonitorView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        offsetForStatusBar=0;
        [self randomBackColor];
        _BigImg=[[UIImage alloc] init];
        
        UIImageView *imv=[[UIImageView alloc] initWithFrame:CGRectMake(0,0, self.frame.size.width, self.frame.size.height-offsetForStatusBar)];
        
        UIScrollView *scrollForimv=[[UIScrollView alloc] initWithFrame:imv.frame];
        [scrollForimv setTag:12122];
        scrollForimv.contentSize=imv.frame.size;
        [self addSubview:scrollForimv];
        [self imvAddRecognizer:imv];
        
        imv.tag=12121;
        imv.image=_BigImg;
        [scrollForimv addSubview:imv];
        [imv release];
    }
    return self;
}
-(void)showImage:(UIImage *)img{
    UIImageView *imv=(UIImageView *)[self viewWithTag:12121];
    if (img) {
        _BigImg=img;
        self.alpha=1;
    }else{
        self.alpha=0;
    }
    if (imv) {
        
        imv.image=_BigImg;
        float wi=img.size.width;
        float he=img.size.height;
        float swi=self.frame.size.width;
        float she=self.frame.size.height-offsetForStatusBar;
        if (wi<=swi&&he<=she) {
            [imv setFrame:CGRectMake(swi/2-wi/2, she/2-he/2+offsetForStatusBar, wi, he)];
        }else{
            //超边际
            if (wi>swi&&he>she) {
                float chawi=wi/swi;
                float chashe=he/she;
                float bx=chawi>=chashe?chawi:chashe;
                
                [imv setFrame:CGRectMake(swi/2-wi/(2*bx), she/2-he/(2*bx)+offsetForStatusBar, wi/bx, he/bx)];
                 //[self showmessage:[NSString stringWithFormat:@"实际 宽%f 高%f ,转换宽%f 高%f",wi,he,wi/bx,he/bx] title:@"双超边际"];
            }else{
                float bx=wi>swi?wi/swi:he/she;
                [imv setFrame:CGRectMake(swi/2-wi/(2*bx), she/2-he/(2*bx)+offsetForStatusBar, wi/bx, he/bx)];
               // [self showmessage:[NSString stringWithFormat:@"实际 宽%f 高%f ,转换宽%f 高%f",wi,he,wi/bx,he/bx] title:@"单超边际"];
            }
        
        }
        //[self randomBackColor];
        
    }else{
        imv=[[UIImageView alloc] initWithFrame:CGRectMake(0, offsetForStatusBar, self.frame.size.width, self.frame.size.height-20)];
        [self imvAddRecognizer:imv];
        imv.tag=12121;
        [self addSubview:imv];
        imv.image=_BigImg;
        
        [imv release];
        //[self randomBackColor];
    }
    
    [self resetScroll];
}
-(void)showmessage:(NSString*)str title:(NSString *)title{
    UIAlertView *alert=[[UIAlertView alloc] initWithTitle:title message:str delegate:nil cancelButtonTitle:nil otherButtonTitles:nil, nil];
    [alert show];
   
    [alert performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:nil afterDelay:1.0];
}
-(void)resetScroll{

    UIScrollView *bgScrollView=(UIScrollView *)[self viewWithTag:12122];
    [bgScrollView setFrame:CGRectMake(0, offsetForStatusBar, self.frame.size.width, self.frame.size.height-offsetForStatusBar)];
}
-(void)randomBackColor{
    NSArray *colorArray = @[[UIColor iOS7redColor],[UIColor iOS7orangeColor],[UIColor iOS7yellowColor],[UIColor iOS7greenColor],[UIColor iOS7lightBlueColor],[UIColor iOS7darkBlueColor],[UIColor iOS7purpleColor],[UIColor iOS7pinkColor],[UIColor iOS7darkGrayColor],[UIColor iOS7lightGrayColor]];
    
    self.backgroundColor=[colorArray objectAtIndex:arc4random()%[colorArray count]];
}

-(void)imvAddRecognizer:(UIImageView *)imv{
    imv.userInteractionEnabled=YES;
    
    UIPinchGestureRecognizer *pinch=[[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(pinchDone:)];
    //[pinch setScale:2.0];
    [imv addGestureRecognizer:pinch];
    [pinch release];
    
    UITapGestureRecognizer *tapG=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGDone:)];
    
    tapG.numberOfTapsRequired=1;
    tapG.numberOfTouchesRequired=1;
    [self addGestureRecognizer:tapG];
    [tapG release];
}
-(void)pinchDone:(UIPinchGestureRecognizer *)recogPinch{
   // [self showmessage:nil title:@"pinch"];
    UIImageView *imview=(UIImageView *)[self viewWithTag:12121];
    recogPinch.view.transform = CGAffineTransformScale(recogPinch.view.transform, recogPinch.scale, recogPinch.scale);

    recogPinch.scale = 1;
    
    if (imview.frame.size.width<=self.frame.size.width&&imview.frame.size.height>self.frame.size.height) {
        [imview setFrame:CGRectMake(self.frame.size.width/2-imview.frame.size.width/2, 0, imview.frame.size.width, imview.frame.size.height)];
    }else
        if(imview.frame.size.width>self.frame.size.width&&imview.frame.size.height<=self.frame.size.height){
            [imview setFrame:CGRectMake(0, self.frame.size.height/2-imview.frame.size.height/2, imview.frame.size.width, imview.frame.size.height)];
        }
        else if(imview.frame.size.width>self.frame.size.width&&imview.frame.size.height>self.frame.size.height){
            [imview setFrame:CGRectMake(0, 0, imview.frame.size.width, imview.frame.size.height)];
        }else if(imview.frame.size.width<=self.frame.size.width&&imview.frame.size.height<=self.frame.size.height){
            
            [imview setFrame:CGRectMake(self.frame.size.width/2-imview.frame.size.width/2, self.frame.size.height/2-imview.frame.size.height/2, imview.frame.size.width, imview.frame.size.height)];
            
        }
    
	
    UIScrollView *bgScrollView=(UIScrollView *)[self viewWithTag:12122];
    bgScrollView.contentSize=CGSizeMake(imview.frame.size.width, imview.frame.size.height);
}
-(void)tapGDone:(UITapGestureRecognizer *)recogPinchtapG{

    //[self showmessage:nil title:@"tap"];
    UIView *actionView=(UIView *)[self viewWithTag:12123];
    UIScrollView *bgScrollView=(UIScrollView *)[self viewWithTag:12122];
    if (actionView) {
        
         [bgScrollView setContentSize:CGSizeMake(bgScrollView.contentSize.width, bgScrollView.contentSize.height-actionView.frame.size.height)];
         [bgScrollView scrollRectToVisible:CGRectMake(bgScrollView.frame.origin.x, bgScrollView.frame.origin.y+actionView.frame.size.height, bgScrollView.contentSize.width, bgScrollView.contentSize.height) animated:YES];
        
        [actionView removeFromSuperview];
        actionView=nil;
    }else{
         actionView=[[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height-40, self.frame.size.width, 40)];//
        actionView.backgroundColor=[UIColor clearColor];
        [actionView  setTag:12123];
        UITapGestureRecognizer *actionViewtapG=[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGDone:)];
        
        actionViewtapG.numberOfTapsRequired=1;
        actionViewtapG.numberOfTouchesRequired=1;
        [actionView addGestureRecognizer:actionViewtapG];
        actionView.userInteractionEnabled=YES;
        [actionViewtapG release];
        
        [bgScrollView setContentSize:CGSizeMake(bgScrollView.contentSize.width, bgScrollView.contentSize.height+actionView.frame.size.height)];
        [bgScrollView setContentOffset:CGPointMake(0, actionView.frame.size.height)];
        [self add_LeftUp_ButtonWith:0.3 Andheigh:0.8 inactionView:actionView];
        [self add_RightUp_ButtonWith:0.3 Andheigh:0.8 inactionView:actionView];
        //[self add_LeftDown_ButtonWith:0.3 Andheigh:0.1 inactionView:actionView];
        //[self add_RightDown_ButtonWith:0.3 Andheigh:0.1 inactionView:actionView];
        [self addSubview:actionView];
        [actionView release];
    }
   
    
}
- (void)image: (UIImage *) image
    didFinishSavingWithError: (NSError *) error
  contextInfo: (void *) contextInfo{
    
    if (!error) {
        [self showmessage:@"save succeed!" title:@"A+"];
    }else{
    
        [self showmessage:error.description title:@"Failed"];
    }
}

-(void)saveImage{
    
    
    UIImageWriteToSavedPhotosAlbum(_BigImg, self,@selector(image:didFinishSavingWithError:contextInfo:), nil);
    
}
-(void)add_LeftUp_ButtonWith:(float)widthPecent Andheigh:(float)heightPercent inactionView:(UIView *)actionView{
    
    
    float btnwidth=actionView.frame.size.width*widthPecent;
    float btnheight=actionView.frame.size.height*heightPercent;
    UIButton *btn=[UIButton buttonWithType:UIButtonTypeCustom];
    [btn setFrame:CGRectMake(actionView.frame.size.width/3-2*btnwidth/3 ,actionView.frame.size.height/8-2*btnheight/8 , btnwidth, btnheight)];
    [btn setBackgroundImage:[UIImage imageNamed:@"ButtonSave.png"] forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:@"ButtonSaveHighlighted.png"] forState:UIControlStateHighlighted];
    [btn setTitle:@"save" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(saveImage) forControlEvents:UIControlEventTouchUpInside];
    [actionView addSubview:btn];
}
-(void)add_LeftDown_ButtonWith:(float)widthPecent Andheigh:(float)heightPercent inactionView:(UIView *)actionView{
    
    
}
-(void)add_RightUp_ButtonWith:(float)widthPecent Andheigh:(float)heightPercent inactionView:(UIView *)actionView{
    float btnwidth=actionView.frame.size.width*widthPecent;
    float btnheight=actionView.frame.size.height*heightPercent;
    UIButton *btn=[UIButton buttonWithType:UIButtonTypeCustom];
    [btn setFrame:CGRectMake(2*actionView.frame.size.width/3-4*btnwidth/3+btnwidth ,actionView.frame.size.height/8-2*btnheight/8 , btnwidth, btnheight)];
    
    [btn setBackgroundImage:[UIImage imageNamed:@"ButtonRecordDone.png"] forState:UIControlStateNormal];
    [btn setBackgroundImage:[UIImage imageNamed:@"ButtonRecordDoneHighlighted.png"] forState:UIControlStateHighlighted];
    [btn setTitle:@"colors" forState:UIControlStateNormal];
    [actionView addSubview:btn];
    [btn addTarget:self action:@selector(randomBackColor) forControlEvents:UIControlEventTouchUpInside];
    
}
-(void)add_RightDown_ButtonWith:(float)widthPecent Andheigh:(float)heightPercent inactionView:(UIView *)actionView{
    
    
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

-(void)dealloc{
    _BigImg=nil;
    [_BigImg release];
    [super dealloc];
}
@end
