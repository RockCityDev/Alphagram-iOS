//
//  TBIntroViewController.h
//  _idx_AccountContext_65E5A86A_ios_min10.0
//
//  Created by Clarence on 2022/8/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface TBStartBtn : UIView
@property (nonatomic, readwrite, strong) UIButton *btn;

@property (nonatomic, readwrite, strong) UIImageView *imgView;
@end


@interface TBIntroViewController : UIViewController

@property (nonatomic) CGRect defaultFrame;

@property (nonatomic, copy) void (^startMessaging)(void);

@property (nonatomic, copy) void (^registerAccount)(void);

@property (nonatomic) bool isEnabled;
@property (nonatomic, readwrite, copy) NSArray <NSString *>*descArr;
@property (nonatomic, readwrite, strong) TBStartBtn *startButton;
@property (nonatomic,copy) NSString *titleButtonText;
@property (nonatomic,copy) NSString *noTelegramTipText;
@property (nonatomic,copy) NSString *noTelegramLoginText;
@end

NS_ASSUME_NONNULL_END
