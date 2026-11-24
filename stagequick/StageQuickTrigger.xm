#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <notify.h>
#import "StageQuickPanel.h"
#import "StageQuickPreferences.h"

static BOOL sqTriggerUnlocked(void) {
    if (![[SQNormalizedPreferences() objectForKey:@"enabled"] boolValue]) return NO;
    Class c = NSClassFromString(@"SBLockScreenManager");
    SEL shared = NSSelectorFromString(@"sharedInstance"), locked = NSSelectorFromString(@"isUILocked");
    id m = [c respondsToSelector:shared] ? ((id(*)(id,SEL))objc_msgSend)(c,shared) : nil;
    if (!m || ![m respondsToSelector:locked]) return YES;
    return !((BOOL(*)(id,SEL))objc_msgSend)(m,locked);
}

@interface YUStageQuickEdgeView : UIView
@property(nonatomic,strong) UIPanGestureRecognizer *pan;
@property(nonatomic,strong) UIView *indicator;
@end
@implementation YUStageQuickEdgeView
- (UIView *)hitTest:(CGPoint)p withEvent:(UIEvent *)event {
    // Leave the rest of the screen untouched; only the lower-right starting corner is ours.
    if (p.x >= self.bounds.size.width - 58.0 && p.y >= self.bounds.size.height - 68.0)
        return self;
    return nil;
}
@end

@interface YUStageQuickGesture : NSObject
@property(nonatomic,strong) UIWindow *window;
@property(nonatomic,strong) YUStageQuickEdgeView *edge;
@property(nonatomic) BOOL keyboard;
@property(nonatomic) CGPoint start;
@property(nonatomic) BOOL tracking;
@end
@implementation YUStageQuickGesture
- (UIWindowScene *)yuStageQuickScene {
    UIWindowScene *chosen = nil;
    for (UIScene *s in UIApplication.sharedApplication.connectedScenes) {
        if (![s isKindOfClass:UIWindowScene.class] || ((UIWindowScene *)s).screen != UIScreen.mainScreen || s.activationState == UISceneActivationStateUnattached) continue;
        chosen = (UIWindowScene *)s;
        if (s.activationState == UISceneActivationStateForegroundActive) break;
    }
    return chosen;
}
- (void)yuStageQuickRefresh {
    if (!sqTriggerUnlocked() || self.keyboard) { self.window.hidden = YES; return; }
    UIWindowScene *scene = [self yuStageQuickScene];
    if (!scene) return;
    if (!self.window || self.window.windowScene != scene) {
        self.window.hidden = YES;
        self.window = [[UIWindow alloc] initWithWindowScene:scene];
        self.window.windowLevel = UIWindowLevelAlert + 1;
        self.window.backgroundColor = UIColor.clearColor;
        self.edge = [[YUStageQuickEdgeView alloc] initWithFrame:CGRectMake(0,0,140,145)];
        self.edge.backgroundColor = UIColor.clearColor;
        self.edge.userInteractionEnabled = YES;
        self.edge.indicator = [[UIView alloc] initWithFrame:CGRectMake(130,78,4,38)];
        self.edge.indicator.backgroundColor = [UIColor colorWithRed:.15 green:.95 blue:.45 alpha:.95];
        self.edge.indicator.layer.cornerRadius = 2;
        self.edge.indicator.alpha = .85;
        [self.edge addSubview:self.edge.indicator];
        UIViewController *vc = [UIViewController new]; vc.view = self.edge;
        self.window.rootViewController = vc;
        self.edge.pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(yuStageQuickPan:)];
        self.edge.pan.maximumNumberOfTouches = 1;
        [self.edge addGestureRecognizer:self.edge.pan];
    }
    CGRect b = scene.coordinateSpace.bounds;
    self.window.frame = CGRectMake(CGRectGetMaxX(b)-140, CGRectGetMaxY(b)-145, 140, 145);
    self.window.hidden = NO;
}
- (void)yuStageQuickPan:(UIPanGestureRecognizer *)g {
    if (!sqTriggerUnlocked() || self.keyboard) return;
    CGPoint p = [g locationInView:self.edge];
    if (g.state == UIGestureRecognizerStateBegan) {
        self.start = p; self.tracking = YES; self.edge.indicator.alpha = 1;
        YUStageQuickSetProgress(0);
        return;
    }
    if (!self.tracking) return;
    CGFloat dx = self.start.x - p.x, dy = self.start.y - p.y;
    CGFloat progress = MAX(0,MIN(1,(dy + MAX(0,dx*.35))/105.0));
    YUStageQuickSetProgress(progress);
    self.edge.indicator.transform = CGAffineTransformMakeScale(1,1 + progress*1.8);
    if (g.state == UIGestureRecognizerStateEnded || g.state == UIGestureRecognizerStateCancelled || g.state == UIGestureRecognizerStateFailed) {
        BOOL open = (dy > 48 && dx > 8 && dy > fabs(dx)*.28);
        self.tracking = NO; self.edge.indicator.transform = CGAffineTransformIdentity; self.edge.indicator.alpha = .85;
        YUStageQuickFinish(open);
    }
}
- (void)yuStageQuickEvent:(NSNotification *)n {
    if ([n.name isEqual:UIKeyboardWillShowNotification]) self.keyboard = YES;
    if ([n.name isEqual:UIKeyboardDidHideNotification]) self.keyboard = NO;
    [self yuStageQuickRefresh];
}
- (void)yuStageQuickStart {
    NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
    for (NSString *name in @[UISceneDidActivateNotification, UIApplicationDidBecomeActiveNotification, UIDeviceOrientationDidChangeNotification, UIKeyboardWillShowNotification, UIKeyboardDidHideNotification])
        [nc addObserver:self selector:@selector(yuStageQuickEvent:) name:name object:nil];
    int token = 0;
    notify_register_dispatch("com.apple.springboard.lockstate", &token, dispatch_get_main_queue(), ^(int t){ [self yuStageQuickRefresh]; });
    [self yuStageQuickRefresh];
}
@end

%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{
        static YUStageQuickGesture *g;
        if (!g) { g = [YUStageQuickGesture new]; [g yuStageQuickStart]; }
    });
}
%end
