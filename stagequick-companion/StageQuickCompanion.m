#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <substrate.h>
#import <string.h>

static const char * const YUSQCList = "DS_llllIIIlIllIlIIIlIIIIIlIllIIlI";
static const char * const YUSQCCell = "DS_IIIIIlIIIlIIIlIllIlIIllllIIIII";
static const char * const YUSQCCellApplication = "DS_lllIllllllllllIllIIlIllIlllIII";
static void (*YUSQCOriginalSelect)(id, SEL, UICollectionView *, NSIndexPath *);
static NSString * const YUSQCDefaults = @"me.tomt000.stageduo.prefs";
// Separate from Dynamic Stage's gesture setting:
// 0 = Original, 1 = Fullscreen, 2 = Combination link.
static NSInteger YUSQCOpenMode(void) {
    NSNumber *mode = [[NSUserDefaults alloc] initWithSuiteName:YUSQCDefaults][@"yuStageQuickOpenMode"];
    return mode ? mode.integerValue : 1;
}
static BOOL YUSQCOpenCombination(NSString *bundleID) {
    NSString *escaped = [bundleID stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"App-prefs://panoramic/pair?app=%@", escaped]];
    UIApplication *application = [UIApplication sharedApplication];
    if (!url || ![application canOpenURL:url]) return NO;
    return [application openURL:url];
}
@interface YUSQCPoint : UILongPressGestureRecognizer
@property(nonatomic, weak) UIView *yuStageQuickCoordinateView;
@property(nonatomic) CGPoint yuStageQuickPoint;
@end
@implementation YUSQCPoint
- (UIGestureRecognizerState)state { return UIGestureRecognizerStateBegan; }
- (CGPoint)locationInView:(UIView *)view { UIView *space=self.yuStageQuickCoordinateView; return view==space?self.yuStageQuickPoint:[space convertPoint:self.yuStageQuickPoint toView:view]; }
@end
static BOOL YUSQCMethodMatches(Method m,const char *types){return m&&types&&strcmp(method_getTypeEncoding(m),types)==0;}
static BOOL YUSQCFromDynamicStage(Class cls){const char *image=cls?class_getImageName(cls):NULL;return image&&[@(image).lastPathComponent isEqualToString:@"DynamicStage.dylib"];}
static void YUSQCSelect(id self,SEL cmd,UICollectionView *collection,NSIndexPath *path){
 if(!NSThread.isMainThread||!collection.window||!path){YUSQCOriginalSelect(self,cmd,collection,path);return;}
 UICollectionViewCell *cell=[collection cellForItemAtIndexPath:path]; if(![cell isKindOfClass:objc_lookUpClass(YUSQCCell)]){YUSQCOriginalSelect(self,cmd,collection,path);return;}
 id app=((id(*)(id,SEL))objc_msgSend)(cell,sel_registerName(YUSQCCellApplication)); NSString *bundle=[app respondsToSelector:@selector(bundleIdentifier)]?((id(*)(id,SEL))objc_msgSend)(app,@selector(bundleIdentifier)):nil;
 if(![bundle isKindOfClass:NSString.class]||!bundle.length){[collection deselectItemAtIndexPath:path animated:NO];return;}
 NSInteger mode = YUSQCOpenMode();
 if (mode == 0) { YUSQCOriginalSelect(self, cmd, collection, path); return; }
 [collection deselectItemAtIndexPath:path animated:NO];
 if (mode == 2 && YUSQCOpenCombination(bundle)) return;
 SEL pressSel=sel_registerName("handleLongPressGesture:"); if(![self respondsToSelector:pressSel])return;
 CGPoint point=[cell convertPoint:CGPointMake(CGRectGetMidX(cell.bounds),CGRectGetMidY(cell.bounds)) toView:collection]; YUSQCPoint *adapter=[YUSQCPoint new];adapter.yuStageQuickCoordinateView=collection;adapter.yuStageQuickPoint=point;
 ((void(*)(id,SEL,UILongPressGestureRecognizer*))objc_msgSend)(self,pressSel,adapter);
}
static void YUSQCTryInstall(NSUInteger attempt){Class list=objc_lookUpClass(YUSQCList),cell=objc_lookUpClass(YUSQCCell);if(!list||!cell){if(attempt<16)dispatch_after(dispatch_time(DISPATCH_TIME_NOW,NSEC_PER_SEC),dispatch_get_main_queue(),^{YUSQCTryInstall(attempt+1);});return;}SEL select=@selector(collectionView:didSelectItemAtIndexPath:);if(!YUSQCFromDynamicStage(list)||!YUSQCFromDynamicStage(cell)||!YUSQCMethodMatches(class_getInstanceMethod(list,select),"v32@0:8@16@24")||!YUSQCMethodMatches(class_getInstanceMethod(list,sel_registerName("handleLongPressGesture:")),"v24@0:8@16")||!YUSQCMethodMatches(class_getInstanceMethod(cell,sel_registerName(YUSQCCellApplication)),"@16@0:8")){NSLog(@"[StageQuickCompanion] Unsupported Dynamic Stage; original unchanged.");return;}MSHookMessageEx(list,select,(IMP)YUSQCSelect,(IMP*)&YUSQCOriginalSelect);NSLog(@"[StageQuickCompanion] tap mode installed");}
__attribute__((constructor))static void YUSQCInitialize(void){dispatch_async(dispatch_get_main_queue(),^{YUSQCTryInstall(0);});}
