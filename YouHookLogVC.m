//
//  YouHookLogVC.m — просмотр лога хуков ( Documents/tiktokyou_hooklog.txt )
//
#import <UIKit/UIKit.h>
#import "BHIManager.h"
#import "YouHookLogVC.h"

#define YOU_BG      [UIColor colorWithRed:0x1E/255.0 green:0x1E/255.0 blue:0x1E/255.0 alpha:1]
#define YOU_TEXT    [UIColor colorWithRed:0xF5/255.0 green:0xF5/255.0 blue:0xF5/255.0 alpha:1]
#define YOU_ACCENT  [UIColor colorWithRed:0xFE/255.0 green:0x2B/255.0 blue:0x54/255.0 alpha:1]

@interface YouHookLogVC : UIViewController
@end

@implementation YouHookLogVC {
    UITextView *_tv;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = YOU_BG;
    self.title = @"Лог хуков";

    _tv = [[UITextView alloc] init];
    _tv.translatesAutoresizingMaskIntoConstraints = NO;
    _tv.backgroundColor = UIColor.clearColor;
    _tv.textColor = YOU_TEXT;
    _tv.font = [UIFont fontWithName:@"Menlo" size:12];
    _tv.editable = NO;
    _tv.text = [HookLog contents];
    [self.view addSubview:_tv];
    [NSLayoutConstraint activateConstraints:@[
        [_tv.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [_tv.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:12],
        [_tv.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-12],
        [_tv.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithImage:[UIImage systemImageNamed:@"trash"]
        style:UIBarButtonItemStylePlain
        target:self action:@selector(clearTapped)];
}

- (void)clearTapped {
    [HookLog clear];
    _tv.text = @"Лог пуст.";
}

@end
