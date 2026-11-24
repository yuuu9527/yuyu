#import <UIKit/UIKit.h>
#import <objc/message.h>
#import "StageQuickPanel.h"
#import "StageQuickPreferences.h"
#import <QuartzCore/QuartzCore.h>

static id sqGet(id obj, NSString *name) { SEL s=NSSelectorFromString(name); return [obj respondsToSelector:s]?((id(*)(id,SEL))objc_msgSend)(obj,s):nil; }
static BOOL sqBool(id obj, NSString *name) { SEL s=NSSelectorFromString(name); return [obj respondsToSelector:s] && ((BOOL(*)(id,SEL))objc_msgSend)(obj,s); }
static BOOL sqUnlocked(void) { id mgr=sqGet(NSClassFromString(@"SBLockScreenManager"),@"sharedInstance"); if(!mgr || ![mgr respondsToSelector:NSSelectorFromString(@"isUILocked")]) return YES; return !sqBool(mgr,@"isUILocked"); }
static id sqWorkspace(void) { return sqGet(NSClassFromString(@"LSApplicationWorkspace"),@"defaultWorkspace"); }
static NSArray *sqApps(void) {
 NSMutableArray *r=[NSMutableArray new]; NSMutableSet *seen=[NSMutableSet new];
 for (id p in sqGet(sqWorkspace(),@"allInstalledApplications")) { @autoreleasepool {
 NSString *b=sqGet(p,@"bundleIdentifier"), *n=sqGet(p,@"localizedName"); NSArray *tags=sqGet(p,@"appTags");
 if (![b isKindOfClass:NSString.class] || !b.length || ![n isKindOfClass:NSString.class] || !n.length || [seen containsObject:b] || [b isEqual:@"com.apple.springboard"] || [tags containsObject:@"hidden"] || sqBool(p,@"isLaunchProhibited") || sqBool(p,@"isPlaceholder") || sqBool(p,@"isHidden")) continue;
 [r addObject:@{ @"id":b,@"name":n }]; [seen addObject:b]; }}
 [r sortUsingComparator:^NSComparisonResult(NSDictionary *a,NSDictionary *b){return [a[@"name"] localizedStandardCompare:b[@"name"]];}]; return r;
}
static UIImage *sqIcon(NSString *bid) { SEL s=NSSelectorFromString(@"_applicationIconImageForBundleIdentifier:format:scale:"); if (![UIImage respondsToSelector:s]) return nil; return ((UIImage*(*)(id,SEL,NSString*,NSInteger,CGFloat))objc_msgSend)(UIImage.class,s,bid,2,UIScreen.mainScreen.scale); }
static UIWindow *sqWindow; static NSMutableArray *sqRecent;
@class YUStageQuickController;
static YUStageQuickController *sqController;
static void sqLaunch(NSString *bid);
@interface YUStageQuickController:UIViewController<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>
@property(nonatomic,strong) UITableView *list;
@property(nonatomic,strong) UITextField *search;
@property(nonatomic,strong) NSArray *apps,*matches,*recents;
@property(nonatomic,strong) UIVisualEffectView *card;
@property(nonatomic,strong) UIButton *back;
@property(nonatomic) CGRect keyboard;
@end
@implementation YUStageQuickController
- (void)loadView { self.view=[UIView new]; self.view.backgroundColor=[UIColor colorWithWhite:0 alpha:.13]; self.back=[UIButton buttonWithType:UIButtonTypeCustom]; self.back.accessibilityLabel=@"关闭快捷面板"; [self.back addTarget:self action:@selector(yuStageQuickClose) forControlEvents:UIControlEventTouchUpInside]; [self.view addSubview:self.back];
 self.card=[[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterial]]; self.card.layer.cornerRadius=22; self.card.clipsToBounds=YES; [self.view addSubview:self.card];
 self.search=[UITextField new]; self.search.placeholder=@"搜索 App"; self.search.accessibilityLabel=@"搜索 App"; self.search.backgroundColor=UIColor.tertiarySystemFillColor; self.search.layer.cornerRadius=12; self.search.leftView=[[UIView alloc] initWithFrame:CGRectMake(0,0,12,1)]; self.search.leftViewMode=UITextFieldViewModeAlways; self.search.clearButtonMode=UITextFieldViewModeWhileEditing; self.search.delegate=self; self.search.returnKeyType=UIReturnKeyDone; [self.search addTarget:self action:@selector(yuStageQuickFilter) forControlEvents:UIControlEventEditingChanged]; [self.card.contentView addSubview:self.search];
 self.list=[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain]; self.list.backgroundColor=UIColor.clearColor; self.list.dataSource=self; self.list.delegate=self; self.list.rowHeight=46; self.list.keyboardDismissMode=UIScrollViewKeyboardDismissModeOnDrag; [self.card.contentView addSubview:self.list]; [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(yuStageQuickKeyboard:) name:UIKeyboardWillChangeFrameNotification object:nil];
}
- (void)yuStageQuickKeyboard:(NSNotification*)n { self.keyboard=[n.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue]; [self.view setNeedsLayout]; }
- (void)viewDidLayoutSubviews { [super viewDidLayoutSubviews]; CGRect b=self.view.bounds; self.back.frame=b; CGRect k=[self.view convertRect:self.keyboard fromView:nil]; CGFloat base=CGRectGetHeight(b)-self.view.safeAreaInsets.bottom-5; if(!CGRectIsEmpty(self.keyboard)&&CGRectIntersectsRect(k,b)) base=MIN(base,CGRectGetMinY(k)-4); CGFloat w=MIN(460,CGRectGetWidth(b)-24), h=MIN(MAX(90,base-self.view.safeAreaInsets.top-6),MIN(390,CGRectGetHeight(b)*.48)); self.card.frame=CGRectMake((CGRectGetWidth(b)-w)/2,base-h,w,h); self.search.frame=CGRectMake(12,12,w-24,38); self.list.frame=CGRectMake(8,54,w-16,MAX(0,h-60)); }
- (void)yuStageQuickClose { YUStageQuickDismiss(); }
- (BOOL)textFieldShouldReturn:(UITextField*)f { [f resignFirstResponder];return YES; }
- (void)yuStageQuickFilter { NSString *q=self.search.text?:@""; NSMutableArray *matches=[NSMutableArray new], *recent=[NSMutableArray new]; for(NSDictionary *app in self.apps) if(!q.length || [app[@"name"] localizedCaseInsensitiveContainsString:q] || [app[@"id"] localizedCaseInsensitiveContainsString:q]) [matches addObject:app]; if(!q.length) for(NSString *bid in sqRecent) for(NSDictionary *app in self.apps) if([bid isEqual:app[@"id"]]){[recent addObject:app];break;} self.matches=matches;self.recents=recent;[self.list reloadData]; }
- (NSInteger)numberOfSectionsInTableView:(UITableView*)t { return self.recents.count?2:1; }
- (NSArray*)yuStageQuickRows:(NSInteger)s { return self.recents.count && !s ? self.recents:self.matches; }
- (NSInteger)tableView:(UITableView*)t numberOfRowsInSection:(NSInteger)s {return [self yuStageQuickRows:s].count;}
- (NSString*)tableView:(UITableView*)t titleForHeaderInSection:(NSInteger)s { return self.recents.count && !s ? @"最近从面板打开" : self.search.text.length?@"搜索结果":@"全部应用"; }
- (UITableViewCell*)tableView:(UITableView*)t cellForRowAtIndexPath:(NSIndexPath*)p { UITableViewCell *c=[t dequeueReusableCellWithIdentifier:@"app"]; if(!c)c=[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"app"]; NSDictionary *a=[self yuStageQuickRows:p.section][p.row]; UIListContentConfiguration *content=[c defaultContentConfiguration];content.text=a[@"name"]; content.image=sqIcon(a[@"id"])?:[UIImage systemImageNamed:@"app"]; content.imageProperties.maximumSize=CGSizeMake(32,32); c.contentConfiguration=content;c.backgroundColor=UIColor.clearColor; return c; }
- (void)tableView:(UITableView*)t didSelectRowAtIndexPath:(NSIndexPath*)p { [t deselectRowAtIndexPath:p animated:YES]; if(!sqUnlocked()){YUStageQuickDismiss();return;} NSString *bid=[self yuStageQuickRows:p.section][p.row][@"id"]; sqLaunch(bid); [sqRecent removeObject:bid];[sqRecent insertObject:bid atIndex:0];if(sqRecent.count>6)[sqRecent removeLastObject]; YUStageQuickDismiss(); }
@end
void YUStageQuickDismiss(void) { if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{YUStageQuickDismiss();}); return;} [sqWindow endEditing:YES];sqWindow.hidden=YES; sqWindow.rootViewController=nil;sqWindow=nil; }
void YUStageQuickShow(void) { if(!NSThread.isMainThread){dispatch_async(dispatch_get_main_queue(),^{YUStageQuickShow();});return;} if(sqWindow || !sqUnlocked())return; UIWindowScene *chosen=nil;for(UIScene *s in UIApplication.sharedApplication.connectedScenes) if([s isKindOfClass:UIWindowScene.class] && ((UIWindowScene*)s).screen==UIScreen.mainScreen && s.activationState!=UISceneActivationStateUnattached){chosen=(UIWindowScene*)s;if(s.activationState==UISceneActivationStateForegroundActive)break;}if(!chosen)return;
 if(!sqRecent)sqRecent=[NSMutableArray new]; YUStageQuickController *vc=[YUStageQuickController new]; sqController=vc; sqWindow=[[UIWindow alloc]initWithWindowScene:chosen];sqWindow.frame=chosen.coordinateSpace.bounds; sqWindow.windowLevel=UIWindowLevelAlert+2;sqWindow.backgroundColor=UIColor.clearColor;sqWindow.rootViewController=vc; [sqWindow makeKeyAndVisible]; vc.card.alpha=.2;vc.card.transform=CGAffineTransformMakeTranslation(0,MIN(330,sqWindow.bounds.size.height*.45));[UIView animateWithDuration:.32 delay:0 usingSpringWithDamping:.82 initialSpringVelocity:.2 options:UIViewAnimationOptionBeginFromCurrentState animations:^{vc.card.alpha=1;vc.card.transform=CGAffineTransformIdentity;} completion:nil]; dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0),^{ NSArray *apps=sqApps(); dispatch_async(dispatch_get_main_queue(),^{if(sqWindow.rootViewController!=vc)return;vc.apps=apps;[vc yuStageQuickFilter];});}); }

static CGFloat sqProgress = 0;
static BOOL sqPendingOpen = NO;
static NSDictionary *sqPrefs(void) { return SQNormalizedPreferences(); }
static BOOL sqEnabled(void) { return [sqPrefs()[@"enabled"] boolValue] || ![[NSUserDefaults standardUserDefaults] objectForKey:@"com.yu.stagequick.disabled"]; }
static void sqLaunch(NSString *bid) {
    NSString *mode=sqPrefs()[@"openMode"];
    if ([mode isEqual:@"Combination"]) {
        NSString *e=[bid stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
        NSURL *u=[NSURL URLWithString:[NSString stringWithFormat:@"App-prefs://panoramic/pair?app=%@",e]];
        SEL o=NSSelectorFromString(@"openURL:"); UIApplication *a=UIApplication.sharedApplication;
        if(u && [a respondsToSelector:o] && ((BOOL(*)(id,SEL,NSURL*))objc_msgSend)(a,o,u)) return;
    }
    id w=sqWorkspace(); SEL s=NSSelectorFromString(@"openApplicationWithBundleID:");
    if([w respondsToSelector:s]) ((BOOL(*)(id,SEL,NSString*))objc_msgSend)(w,s,bid);
}
void YUStageQuickSetProgress(CGFloat progress) {
    dispatch_async(dispatch_get_main_queue(), ^{ sqProgress=MAX(0,MIN(1,progress)); if(sqWindow && sqWindow.rootViewController==sqController){ CGFloat h=sqWindow.bounds.size.height; sqController.card.transform=CGAffineTransformMakeTranslation(0,(1-sqProgress)*MIN(330,h*.45)); sqController.card.alpha=.35+.65*sqProgress; }});
}
void YUStageQuickFinish(BOOL opened) {
    dispatch_async(dispatch_get_main_queue(), ^{ if(opened){ YUStageQuickShow(); } else { YUStageQuickDismiss(); } });
}
