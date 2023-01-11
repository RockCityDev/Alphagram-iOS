//
//  TBIntroViewController.m
//  _idx_AccountContext_65E5A86A_ios_min10.0
//
//  Created by Clarence on 2022/8/2.
//

#import "TBIntroViewController.h"
#import "TBIntroPageView.h"
#include "animations.h"


UIColor* themeColor() {
    return [UIColor colorWithRed:75/255.0 green:91/255.0 blue:255/255.0 alpha:1];
}

@interface TBStartBtn()

@end

@implementation TBStartBtn

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.btn = [UIButton buttonWithType:UIButtonTypeCustom];
//        [self.btn setTitle:@"Telegram " forState:UIControlStateNormal];
        [self.btn setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [self.btn.titleLabel setFont:[UIFont systemFontOfSize:19 weight:UIFontWeightMedium]];
        self.btn.titleLabel.adjustsFontSizeToFitWidth = YES;
        [self.btn setBackgroundColor:themeColor()];
        self.btn.frame = self.bounds;
        self.btn.layer.masksToBounds = YES;
        self.btn.layer.cornerRadius = CGRectGetHeight(self.bounds)/2.0;
        self.btn.contentEdgeInsets = UIEdgeInsetsMake(0, 34, 0, 54);
        
        self.imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_arrow_login_btn.png"]];
        self.imgView.frame = CGRectMake(CGRectGetWidth(self.bounds) - 10 - 34, 10, 34, 34);
        self.imgView.userInteractionEnabled = NO;
        [self addSubview:self.btn];
        [self addSubview:self.imgView];
    }
    return self;
}

@end

@interface UIScrollView (TBCurrentPage)

- (int)currentPage;

- (void)setPage:(NSInteger)page;

- (int)currentPageMin;

- (int)currentPageMax;

@end

@implementation UIScrollView (TBCurrentPage)

- (int)currentPage
{
    CGFloat pageWidth = self.frame.size.width;
    return (int)floor((self.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
}

- (int)currentPageMin
{
    CGFloat pageWidth = self.frame.size.width;
    return (int)floor((self.contentOffset.x - pageWidth / 2 - pageWidth / 2) / pageWidth) + 1;
}

- (int)currentPageMax
{
    CGFloat pageWidth = self.frame.size.width;
    return (int)floor((self.contentOffset.x - pageWidth / 2 + pageWidth / 2 ) / pageWidth) + 1;
}

- (void)setPage:(NSInteger)page
{
    self.contentOffset = CGPointMake(self.frame.size.width*page, 0);
}
@end


@interface TBIntroView : UIView

@property (nonatomic, copy) void (^onLayout)();

@end

@implementation TBIntroView

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (_onLayout) {
        _onLayout();
    }
}

@end

@interface TBIntroViewController ()<UIScrollViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, readwrite, strong) NSMutableArray <TBIntroPageView *>*pageViews;

@property (nonatomic, readwrite, strong) UIScrollView *pageScrollView;

@property (nonatomic, readwrite, assign) NSInteger currentPage;

@property (nonatomic, readwrite, strong) UIPageControl *pageControl;

@property(nonatomic, strong) id didEnterBackgroundObserver;

@property (nonatomic, readwrite, strong) id willEnterBackgroundObserver;

@property (nonatomic, readwrite, assign) BOOL loadedView;

#pragma mark -

@property (nonatomic, readwrite, copy) NSArray <UIImage *>*imageArr;


#pragma mark -


@property (nonatomic, readwrite, strong) UILabel *promoteLabel;

@property (nonatomic, readwrite, strong) UIButton *registerBtn;

@end

@implementation TBIntroViewController

- (instancetype)init
{
    self = [super init];
    if (self != nil)
    {
        _isEnabled = true;
        
//        self.descArr = @[@" Telegram ", @"", @""];
        self.imageArr = @[[UIImage imageNamed:@"image_page1_login"], [UIImage imageNamed:@"image_page2_login"], [UIImage imageNamed:@"image_page3_login"]];
    
        self.automaticallyAdjustsScrollViewInsets = false;
    
        self.didEnterBackgroundObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(__unused NSNotification *notification)
        {
        }];
        
        self.willEnterBackgroundObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(__unused NSNotification *notification)
        {
        }];
    }
    return self;
}

- (void)loadView {
    self.view = [[TBIntroView alloc] initWithFrame:self.defaultFrame];
    __weak TBIntroViewController *weakSelf = self;
    ((TBIntroView *)self.view).onLayout = ^{
        __strong TBIntroViewController *strongSelf = weakSelf;
        if (strongSelf != nil) {
            [strongSelf updateLayout];
        }
    };
    
    [self viewDidLoad];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGRect mainBounds = UIScreen.mainScreen.bounds;
    
    if (_loadedView) {
        return;
    }
    _loadedView = true;
    
    self.view.backgroundColor = UIColor.whiteColor;
    
    _pageScrollView = [[UIScrollView alloc]initWithFrame:self.view.bounds];
    _pageScrollView.clipsToBounds = true;
    _pageScrollView.opaque = true;
    _pageScrollView.clearsContextBeforeDrawing = false;
    [_pageScrollView setShowsHorizontalScrollIndicator:false];
    [_pageScrollView setShowsVerticalScrollIndicator:false];
    _pageScrollView.pagingEnabled = true;
    _pageScrollView.contentSize = CGSizeMake(self.imageArr.count * self.view.bounds.size.width, self.view.bounds.size.height);
    _pageScrollView.delegate = self;
    [self.view addSubview:_pageScrollView];
    
    _pageViews = [NSMutableArray array];
    
    for (NSUInteger i = 0; i < self.imageArr.count; i++)
    {
        TBIntroPageView *p = [[TBIntroPageView alloc] initWithFrame:CGRectMake(i * self.view.bounds.size.width, 0, self.view.bounds.size.width, self.view.bounds.size.height) image:self.imageArr[i] description:self.descArr[i]];
        p.opaque = true;
        p.clearsContextBeforeDrawing = false;
        [_pageViews addObject:p];
        [_pageScrollView addSubview:p];
    }
    [_pageScrollView setPage:0];

    _startButton = [[TBStartBtn alloc] initWithFrame:CGRectMake(33 , CGRectGetHeight(self.view.bounds) - 125 - 53, CGRectGetWidth(self.view.bounds) - 33 * 2, 53)];
    
    [_startButton.btn addTarget:self action:@selector(startButtonPress) forControlEvents:UIControlEventTouchUpInside];
    [_startButton.btn setTitle:self.titleButtonText forState:UIControlStateNormal];

    [self.view addSubview:_startButton];
    
    _pageControl = [[UIPageControl alloc] init];
    _pageControl.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin;
    _pageControl.userInteractionEnabled = false;
    [_pageControl setNumberOfPages:self.imageArr.count];
    _pageControl.pageIndicatorTintColor = [UIColor colorWithRed:134/255.0 green:134/255.0 blue:134/255.0 alpha:1];
    _pageControl.currentPageIndicatorTintColor = themeColor();
    
    _pageControl.hidden = self.descArr.count > 1 ? false : true;
    [self.view addSubview:_pageControl];
    
    self.promoteLabel = [[UILabel alloc] init];
    self.promoteLabel.numberOfLines = 1;
    self.promoteLabel.text = self.noTelegramTipText;
    self.promoteLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightRegular];
    self.promoteLabel.textColor = [UIColor blackColor];
    CGFloat rate =  CGRectGetWidth(mainBounds) / 390.0;
    self.promoteLabel.frame = CGRectMake(74 * rate, CGRectGetMaxY(self.startButton.frame) + 38, CGRectGetWidth(mainBounds), 15);
    [self.view addSubview:self.promoteLabel];
    
    
    self.registerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    NSAttributedString *attr = [[NSAttributedString alloc] initWithString:self.noTelegramLoginText attributes:@{NSForegroundColorAttributeName:themeColor(), NSFontAttributeName:[UIFont systemFontOfSize:14 weight:UIFontWeightRegular]}];
    [self.registerBtn setAttributedTitle:attr forState:UIControlStateNormal];
    [self.registerBtn addTarget:self action:@selector(registerPress) forControlEvents:UIControlEventTouchUpInside];
    self.registerBtn.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 0);
    
    CGSize titleSize = [attr boundingRectWithSize:mainBounds.size options:0 context:nil].size;
    self.registerBtn.frame = CGRectMake(CGRectGetWidth(mainBounds) - 74*rate - titleSize.width, CGRectGetMinY(self.promoteLabel.frame) - 10, titleSize.width + 10, titleSize.height + 20);
    
    [self.view addSubview:self.registerBtn];

}

-(void)setTitleButtonText:(NSString *)titleButtonText {
    _titleButtonText = titleButtonText;
    [self.startButton.btn setTitle:titleButtonText forState:UIControlStateNormal];
}

-(void)setNoTelegramTipText:(NSString *)noTelegramTipText {
    _noTelegramTipText = noTelegramTipText;
}

-(void)setNoTelegramLoginText:(NSString *)noTelegramLoginText {
    _noTelegramLoginText = noTelegramLoginText;
}

- (BOOL)shouldAutorotate
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return true;
    
    return false;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        return UIInterfaceOrientationMaskAll;
    
    return UIInterfaceOrientationMaskPortrait;
}

- (void)updateLayout
{
    _pageControl.frame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - 232 - 7, self.view.bounds.size.width, 7);
    
    _pageScrollView.frame = self.view.bounds;
    
    _pageScrollView.contentSize=CGSizeMake(_imageArr.count * self.view.bounds.size.width, self.view.bounds.size.height);
    
    _pageScrollView.contentOffset = CGPointMake(_currentPage * self.view.bounds.size.width, 0);
    
    [_pageViews enumerateObjectsUsingBlock:^(UIView *pageView, NSUInteger index, __unused BOOL *stop)
     {
         pageView.frame = CGRectMake(index * self.view.bounds.size.width, 0, self.view.bounds.size.width, self.view.bounds.size.height);
     }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
}

- (void)startButtonPress
{
    if (_startMessaging) {
        _startMessaging();
    }
}

- (void)registerPress {
    if (_registerAccount) {
        _registerAccount();
    }
}

- (void)updateAndRender
{
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_didEnterBackgroundObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:_willEnterBackgroundObserver];
}


static CGFloat x;
static bool justEndDragging;

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)__unused decelerate
{
    x = scrollView.contentOffset.x;
    justEndDragging = true;
}

NSInteger _current_page_end;

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat offset = (scrollView.contentOffset.x - _currentPage * scrollView.frame.size.width) / self.view.frame.size.width;
    
    set_scroll_offset((float)offset);
    
    if (justEndDragging)
    {
        justEndDragging = false;
        
        CGFloat page = scrollView.contentOffset.x / scrollView.frame.size.width;
        CGFloat sign = scrollView.contentOffset.x - x;
        
        if (sign > 0)
        {
            if (page > _currentPage)
                _currentPage++;
        }
        
        if (sign < 0)
        {
            if (page < _currentPage)
                _currentPage--;
        }
        
        _currentPage = MAX(0, MIN(5, _currentPage));
        _current_page_end = _currentPage;
    }
    else
    {
        if (_pageScrollView.contentOffset.x > _current_page_end*_pageScrollView.frame.size.width)
        {
            if (_pageScrollView.currentPageMin > _current_page_end) {
                _currentPage = [_pageScrollView currentPage];
                _current_page_end = _currentPage;
            }
        }
        else
        {
            if (_pageScrollView.currentPageMax < _current_page_end)
            {
                _currentPage = [_pageScrollView currentPage];
                _current_page_end = _currentPage;
            }
        }
    }
    
    [_pageControl setCurrentPage:_currentPage];
}


- (void)setIsEnabled:(bool)isEnabled {
    if (_isEnabled != isEnabled) {
        _isEnabled = isEnabled;
        _startButton.alpha = _isEnabled ? 1.0 : 0.6;
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
