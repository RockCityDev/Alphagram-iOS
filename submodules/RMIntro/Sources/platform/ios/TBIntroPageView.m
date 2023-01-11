//
//  TBIntroPageView.m
//  _idx_AccountContext_65E5A86A_ios_min10.0
//
//  Created by Clarence on 2022/8/2.
//

#import "TBIntroPageView.h"

@interface TBIntroPageView ()

@property (nonatomic, readwrite, copy) NSString *desc;

@property (nonatomic, readwrite, strong) UIImage *image;

@property (nonatomic, readwrite, strong) UILabel *descLabel;

@property (nonatomic, readwrite, strong) UIImageView *imgView;

@end

@implementation TBIntroPageView

#define IPAD ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)

- (id)initWithFrame:(CGRect)frame image:(UIImage *)image description:(NSString *)description
{
    self = [super initWithFrame:frame];
    if (self) {
        self.opaque = YES;
        
        self.image = image;
        self.desc = description;
        
        self.descLabel = [[UILabel alloc] init];
        self.descLabel.numberOfLines = 1;
        self.descLabel.textColor = UIColor.blackColor;
        self.descLabel.font = [UIFont systemFontOfSize:19 weight:UIFontWeightMedium];
        self.descLabel.textAlignment = NSTextAlignmentCenter;
        self.descLabel.text = self.desc;
        
        self.imgView = [[UIImageView alloc] initWithImage:self.image];
        self.imgView.contentMode = UIViewContentModeScaleAspectFit;
        self.imgView.layer.masksToBounds = YES;
        self.imgView.backgroundColor = [UIColor colorWithRed:3/255.0 green:189/255.0 blue:255/255.0 alpha:1];
        
        CGFloat imgH = CGRectGetHeight(UIScreen.mainScreen.bounds) - (286 + 24);
        CGRect imgFrame = CGRectMake(0, 0, CGRectGetWidth(frame), imgH);
        self.imgView.frame = imgFrame;
        self.descLabel.frame = CGRectMake(0, CGRectGetMaxY(imgFrame) + 27, CGRectGetWidth(frame), 26);
        
        [self addSubview:self.imgView];
        [self addSubview:self.descLabel];
        
    }
    return self;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
