#import <UIKit/UIKit.h>
#import "YsLiquidClockConfig.h"
#import "YsLiquidClockPreferences.h"
#import "YsLiquidClockPrivate.h"
#import "YsLiquidClockStyle.h"

// 锁屏时钟的 label 是私有的 UILabel 子类，按文本形态识别，
// 避免依赖具体的私有类名或私有属性名。

static BOOL ys_liquidclock_isClockText(NSString *text) {
    if (text.length == 0 || text.length > 9) return NO;
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"^[0-9]{1,2}(:[0-9]{2})?( ?[AP]M)?$"
                                                          options:0 error:NULL];
    });
    return [regex firstMatchInString:text options:0 range:NSMakeRange(0, text.length)] != nil;
}

static BOOL ys_liquidclock_isClockLabel(UILabel *label) {
    if (ys_liquidclock_isClockText(label.text)) return YES;
    NSAttributedString *attributed = label.attributedText;
    return attributed.length > 0 && ys_liquidclock_isClockText(attributed.string);
}

static void ys_liquidclock_styleTree(UIView *view, NSUInteger depth, NSUInteger limit) {
    if (!view || depth > limit) return;
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        if (ys_liquidclock_isClockLabel(label)) {
            [[YsLiquidClockStyle ys_liquidclock_style] ys_liquidclock_applyToLabel:label];
            return;
        }
    }
    for (UIView *subview in view.subviews) {
        ys_liquidclock_styleTree(subview, depth + 1, limit);
    }
}

// 设置变更后立即刷新已存在的时钟，不必注销 SpringBoard。
static void ys_liquidclock_refreshWindows(void) {
    // UIApplication.windows 自 iOS 15 起废弃，改为遍历已连接窗口场景。
    for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) continue;
        for (UIWindow *window in ((UIWindowScene *)scene).windows) {
            ys_liquidclock_styleTree(window, 0, 16);
        }
    }
}

%hook SBFLockScreenDateView

- (void)layoutSubviews {
    %orig;
    ys_liquidclock_styleTree(self, 0, 6);
}

- (void)didMoveToWindow {
    %orig;
    ys_liquidclock_styleTree(self, 0, 6);
}

%end

%hook SBFLockScreenDateViewController

- (void)viewDidLayoutSubviews {
    %orig;
    ys_liquidclock_styleTree(self.view, 0, 6);
}

%end

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    // 锁屏视图可能在启动后才创建，延后一次补齐。
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        ys_liquidclock_refreshWindows();
    });
}

%end

%ctor {
    @autoreleasepool {
        // Readers load a snapshot; they never write default preferences.
        [[YsLiquidClockConfig ys_liquidclock_shared] ys_liquidclock_isEnabled];
        [[NSNotificationCenter defaultCenter] addObserverForName:YsLiquidClockPreferencesChanged
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
            ys_liquidclock_refreshWindows();
        }];
    }
}
