//
//  YouFloatingHub.m — плавающая кнопка TikTok You (аналог Android widget_container):
//  перетаскивание пальцем, тап = анти-выгорание, долгое нажатие = меню настроек мода.
//
#import <UIKit/UIKit.h>
#import "BHIManager.h"
#import "YouFloatingHub.h"
#import "YouSettingsViewController.h"

#define YOU_ACCENT  [UIColor colorWithRed:0xFE/255.0 green:0x2B/255.0 blue:0x54/255.0 alpha:1]
#define YOU_DIM     [UIColor colorWithWhite:0 alpha:0.55]

static UIWindow *youHubWindow = nil;

@interface YouFloatingHubWindow : UIWindow
@end
@implementation YouFloatingHubWindow
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    // pass touches through except on the hub button
    for (UIView *v in self.subviews) {
        if ([v pointInside:[self convertPoint:point toView:v] withEvent:event]) return YES;
    }
    return NO;
}
@end

@interface YouHubButton : UIButton
@property (nonatomic, assign) CGPoint dragStart;
@end
@implementation YouHubButton

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *t = touches.anyObject;
    _dragStart = [t locationInView:self.superview];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *t = touches.anyObject;
    CGPoint p = [t locationInView:self.superview];
    self.center = CGPointMake(self.center.x + (p.x - _dragStart.x), self.center.y + (p.y - _dragStart.y));
    _dragStart = p;
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *t = touches.anyObject;
    NSTimeInterval press = t.timestamp; // unused; use touch duration via tap recognizer
    [super touchesEnded:touches withEvent:event];
}

@end

@interface YouFloatingHub ()
@property (nonatomic, strong) YouHubButton *button;
@property (nonatomic, strong) UIView *dimOverlay;
@end
@implementation YouFloatingHub

+ (YouFloatingHub *)shared {
    static YouFloatingHub *h = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{ h = [YouFloatingHub new]; });
    return h;
}

- (void)show {
    if (youHubWindow) return;
    youHubWindow = [[YouFloatingHubWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    youHubWindow.windowLevel = UIWindowLevelAlert + 100;
    youHubWindow.backgroundColor = UIColor.clearColor;
    youHubWindow.hidden = NO;

    // dim overlay for anti-burnout (added to app's key window, not hub window)
    [self installDimOverlayIfNeeded];

    CGFloat size = 52;
    YouHubButton *btn = [[YouHubButton alloc] initWithFrame:CGRectMake([UIScreen mainScreen].bounds.size.width - size - 16, 180, size, size)];
    btn.backgroundColor = [YOU_ACCENT colorWithAlphaComponent:0.92];
    btn.layer.cornerRadius = size / 2;
    btn.clipsToBounds = YES;
    btn.userInteractionEnabled = YES;
    [btn setImage:[UIImage systemImageNamed:@"flame.fill"] forState:UIControlStateNormal];
    btn.tintColor = UIColor.whiteColor;
    [btn addTarget:self action:@selector(hubTapped) forControlEvents:UIControlEventTouchUpInside];

    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(hubLongPressed)];
    lp.minimumPressDuration = 0.45;
    [btn addGestureRecognizer:lp];

    self.button = btn;
    [youHubWindow addSubview:btn];
    [youHubWindow setHidden:NO];
}

- (void)hubTapped {
    [self toggleBurnout];
}

- (void)hubLongPressed {
    [self openMenu];
}

- (void)toggleBurnout {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    BOOL on = ![d boolForKey:@"anti_burnout"];
    [d setBool:on forKey:@"anti_burnout"];
    [self applyBurnout:on];
    NSString *msg = on ? @"Антивыгорание включено" : @"Антивыгорание выключено";
    [self toast:msg];
}

- (void)applyBurnout:(BOOL)on {
    if (self.dimOverlay.superview) {
        CGFloat alpha = on ? [BHIManager feedOverlayTransparency] / 100.0 : 0;
        [UIView animateWithDuration:0.25 animations:^{
            self.dimOverlay.alpha = alpha;
        }];
    }
}

- (void)installDimOverlayIfNeeded {
    if (self.dimOverlay) {
        if (!self.dimOverlay.superview) {
            [[UIApplication sharedApplication].keyWindow addSubview:self.dimOverlay];
        }
        return;
    }
    UIView *dim = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    dim.backgroundColor = [UIColor colorWithWhite:0 alpha:1];
    dim.alpha = 0;
    dim.userInteractionEnabled = NO;
    dim.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.dimOverlay = dim;
    [[UIApplication sharedApplication].keyWindow addSubview:dim];
    if ([BHIManager antiBurnout]) {
        dim.alpha = [BHIManager feedOverlayTransparency] / 100.0;
    }
}

- (void)openMenu {
    UIViewController *root = [UIApplication sharedApplication].keyWindow.rootViewController;
    UIViewController *top = root;
    while (top.presentedViewController) top = top.presentedViewController;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:[[YouSettingsViewController alloc] init]];
    nav.modalPresentationStyle = UIModalPresentationFullScreen;
    [top presentViewController:nav animated:YES completion:nil];
}

- (void)toast:(NSString *)text {
    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *w = youHubWindow ?: [UIApplication sharedApplication].keyWindow;
        UILabel *toast = [[UILabel alloc] init];
        toast.text = text;
        toast.textColor = UIColor.whiteColor;
        toast.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        toast.layer.cornerRadius = 10;
        toast.clipsToBounds = YES;
        toast.textAlignment = NSTextAlignmentCenter;
        toast.font = [UIFont systemFontOfSize:14];
        toast.frame = CGRectMake(20, w.bounds.size.height - 90, w.bounds.size.width - 40, 40);
        toast.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        [w addSubview:toast];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3 animations:^{ toast.alpha = 0; } completion:^(BOOL f) { [toast removeFromSuperview]; }];
        });
    });
}

@end
