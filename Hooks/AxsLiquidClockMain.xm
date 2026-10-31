#import <UIKit/UIKit.h>
#import "AxsLiquidClockConfig.h"
#import "AxsLiquidClockPreferences.h"
#import "AxsLiquidClockPrivate.h"
#import "AxsLiquidClockStyle.h"

// 锁屏时钟的 label 是私有的 UILabel 子类，按文本形态识别，
// 避免依赖具体的私有类名或私有属性名。

static BOOL axs_liquidclock_isClockText(NSString *text) {
    if (text.length == 0 || text.length > 9) return NO;
    static NSRegularExpression *regex;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        regex = [NSRegularExpression regularExpressionWithPattern:@"^[0-9]{1,2}(:[0-9]{2})?( ?[AP]M)?$"
                                                          options:0 error:NULL];
    });
    return [regex firstMatchInString:text options:0 range:NSMakeRange(0, text.length)] != nil;
}

static BOOL axs_liquidclock_isClockLabel(UILabel *label) {
    if (axs_liquidclock_isClockText(label.text)) return YES;
    NSAttributedString *attributed = label.attributedText;
    return attributed.length > 0 && axs_liquidclock_isClockText(attributed.string);
}

static void axs_liquidclock_styleTree(UIView *view, NSUInteger depth, NSUInteger limit) {
    if (!view || depth > limit) return;
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        if (axs_liquidclock_isClockLabel(label)) {
            [[AxsLiquidClockStyle axs_liquidclock_style] axs_liquidclock_applyToLabel:label];
            return;
        }
    }
    for (UIView *subview in view.subviews) {
        axs_liquidclock_styleTree(subview, depth + 1, limit);
    }
}

// 设置变更后立即刷新已存在的时钟，不必注销 SpringBoard。
static void axs_liquidclock_refreshWindows(void) {
    for (UIWindow *window in [UIApplication sharedApplication].windows) {
        axs_liquidclock_styleTree(window, 0, 16);
    }
}

%hook SBFLockScreenDateView

- (void)layoutSubviews {
    %orig;
    axs_liquidclock_styleTree(self, 0, 6);
}

- (void)didMoveToWindow {
    %orig;
    axs_liquidclock_styleTree(self, 0, 6);
}

%end

%hook SBFLockScreenDateViewController

- (void)viewDidLayoutSubviews {
    %orig;
    axs_liquidclock_styleTree(self.view, 0, 6);
}

%end

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    // 锁屏视图可能在启动后才创建，延后一次补齐。
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        axs_liquidclock_refreshWindows();
    });
}

%end

%ctor {
    @autoreleasepool {
        // Readers load a snapshot; they never write default preferences.
        [[AxsLiquidClockConfig axs_liquidclock_shared] axs_liquidclock_isEnabled];
        [[NSNotificationCenter defaultCenter] addObserverForName:AxsLiquidClockPreferencesChanged
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification *note) {
            axs_liquidclock_refreshWindows();
        }];
    }
}
