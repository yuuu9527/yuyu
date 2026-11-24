#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <notify.h>
#import "StageQuickPanel.h"

static BOOL sqTriggerUnlocked(void) {
 Class c=NSClassFromString(@"SBLockScreenManager"); SEL shared=NSSelectorFromString(@"sharedInstance"), locked=NSSelectorFromString(@"isUILocked");
 id m=[c respondsToSelector:shared]?((id(*)(id,SEL))objc_msgSend)(c,shared):nil;
 return [m respondsToSelector:locked] && !((BOOL(*)(id,SEL))objc_msgSend)(m,locked);
}
@interface YUStageQuickEdgeWindow:UIWindow @end
@implementation YUStageQuickEdgeWindow
- (BOOL)canBecomeKeyWindow { return NO; }
- (UIView*)hitTest:(CGPoint)p withEvent:(UIEvent*)e { return sqTriggerUnlocked()?[super hitTest:p withEvent:e]:nil; }
@end
@interface YUStageQuickGesture:NSObject
@property(strong,nonatomic) YUStageQuickEdgeWindow *window;
@property(nonatomic) BOOL keyboard;
@end
@implementation YUStageQuickGesture
- (void)yuStageQuickRefresh {
 if(!sqTriggerUnlocked() || self.keyboard){self.window.hidden=YES;if(!sqTriggerUnlocked())YUStageQuickDismiss();return;}
 UIWindowScene *scene=self.window.windowScene;
 if(!scene || scene.activationState==UISceneActivationStateUnattached) {scene=nil; for(UIScene *s in UIApplication.sharedApplication.connectedScenes){if(![s isKindOfClass:UIWindowScene.class]||((UIWindowScene*)s).screen!=UIScreen.mainScreen ||s.activationState==UISceneActivationStateUnattached)continue; scene=(UIWindowScene*)s;if(s.activationState==UISceneActivationStateForegroundActive)break;}}
 if(!scene)return;
 if(scene!=self.window.windowScene || !self.window){ self.window.hidden=YES; YUStageQuickEdgeWindow *w=[[YUStageQuickEdgeWindow alloc]initWithWindowScene:scene]; w.rootViewController=[UIViewController new];w.rootViewController.view.backgroundColor=UIColor.clearColor; w.backgroundColor=UIColor.clearColor;w.windowLevel=UIWindowLevelAlert+1; UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(yuStageQuickPan:)];pan.maximumNumberOfTouches=1;[w.rootViewController.view addGestureRecognizer:pan]; self.window=w; }
 CGRect b=scene.coordinateSpace.bounds;self.window.frame=CGRectMake(CGRectGetMaxX(b)-58,CGRectGetMaxY(b)-35,46,20); self.window.hidden=NO;
}
- (void)yuStageQuickPan:(UIPanGestureRecognizer*)g { if(g.state!=UIGestureRecognizerStateEnded || !sqTriggerUnlocked())return; CGPoint t=[g translationInView:self.window]; if(t.y < -31 && t.x < -8 && -t.y > fabs(t.x)*.40) YUStageQuickShow(); }
- (void)yuStageQuickEvent:(NSNotification*)n { if([n.name isEqual:UIKeyboardWillShowNotification])self.keyboard=YES; if([n.name isEqual:UIKeyboardDidHideNotification])self.keyboard=NO; [self yuStageQuickRefresh]; }
- (void)yuStageQuickStart { NSNotificationCenter *nc=NSNotificationCenter.defaultCenter; for(NSString *name in @[UISceneDidActivateNotification,UIApplicationDidBecomeActiveNotification,UIDeviceOrientationDidChangeNotification,UIKeyboardWillShowNotification,UIKeyboardDidHideNotification]) [nc addObserver:self selector:@selector(yuStageQuickEvent:) name:name object:nil]; int token; notify_register_dispatch("com.apple.springboard.lockstate",&token,dispatch_get_main_queue(),^(int t){[self yuStageQuickRefresh];}); [self yuStageQuickRefresh]; }
@end
%hook SpringBoard
- (void)applicationDidFinishLaunching:(id)application { %orig; dispatch_async(dispatch_get_main_queue(),^{static YUStageQuickGesture *g; if(!g){g=[YUStageQuickGesture new];[g yuStageQuickStart];}}); }
%end
