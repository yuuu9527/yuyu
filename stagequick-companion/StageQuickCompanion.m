#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <substrate.h>
#import <string.h>

// Dynamic Stage 1.2. Keep its gesture, list, settings and panel lifecycle intact.
static const char * const YUSQCList = "DS_llllIIIlIllIlIIIlIIIIIlIllIIlI";
static const char * const YUSQCCell = "DS_IIIIIlIIIlIIIlIllIlIIllllIIIII";
static const char * const YUSQCCellApplication = "DS_lllIllllllllllIllIIlIllIlllIII";
static void (*YUSQCOriginalSelect)(id, SEL, UICollectionView *, NSIndexPath *);

// A local adapter for the original handler's two queries. Never installed in a view or sent to the system.
@interface YUSQCPoint : UILongPressGestureRecognizer
@property(nonatomic, weak) UIView *yuStageQuickCoordinateView;
@property(nonatomic) CGPoint yuStageQuickPoint;
@end
@implementation YUSQCPoint
- (UIGestureRecognizerState)state { return UIGestureRecognizerStateBegan; }
- (CGPoint)locationInView:(UIView *)view {
    UIView *space = self.yuStageQuickCoordinateView;
    return view == space ? self.yuStageQuickPoint : [space convertPoint:self.yuStageQuickPoint toView:view];
}
@end

static BOOL YUSQCMethodMatches(Method m, const char *types) {
    if (!m || !types) return NO;
    const char *actual = method_getTypeEncoding(m);
    return actual && strcmp(actual, types) == 0;
}
static BOOL YUSQCFromDynamicStage(Class cls) {
    const char *image = cls ? class_getImageName(cls) : NULL;
    return image && [@(image).lastPathComponent isEqualToString:@"DynamicStage.dylib"];
}
static void YUSQCSelect(id self, SEL cmd, UICollectionView *collection, NSIndexPath *path) {
    if (!NSThread.isMainThread || !collection.window || !path) {
        YUSQCOriginalSelect(self, cmd, collection, path);
        return;
    }
    UICollectionViewCell *cell = [collection cellForItemAtIndexPath:path];
    if (![cell isKindOfClass:objc_lookUpClass(YUSQCCell)]) {
        YUSQCOriginalSelect(self, cmd, collection, path);
        return;
    }
    SEL appSel = sel_registerName(YUSQCCellApplication);
    id app = ((id (*)(id, SEL))objc_msgSend)(cell, appSel);
    SEL bundleSel = @selector(bundleIdentifier);
    NSString *bundle = [app respondsToSelector:bundleSel] ? ((id (*)(id, SEL))objc_msgSend)(app, bundleSel) : nil;
    SEL pressSel = sel_registerName("handleLongPressGesture:");
    if (![bundle isKindOfClass:NSString.class] || !bundle.length || ![self respondsToSelector:pressSel]) {
        [collection deselectItemAtIndexPath:path animated:NO];
        return;
    }
    CGPoint point = [cell convertPoint:CGPointMake(CGRectGetMidX(cell.bounds), CGRectGetMidY(cell.bounds)) toView:collection];
    if (![[collection indexPathForItemAtPoint:point] isEqual:path]) {
        [collection deselectItemAtIndexPath:path animated:NO];
        return;
    }
    [collection deselectItemAtIndexPath:path animated:NO];
    YUSQCPoint *adapter = [YUSQCPoint new];
    adapter.yuStageQuickCoordinateView = collection;
    adapter.yuStageQuickPoint = point;
    ((void (*)(id, SEL, UILongPressGestureRecognizer *))objc_msgSend)(self, pressSel, adapter);
}

static void YUSQCTryInstall(NSUInteger attempt) {
    Class list = objc_lookUpClass(YUSQCList), cell = objc_lookUpClass(YUSQCCell);
    if (!list || !cell) {
        if (attempt < 16) dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC), dispatch_get_main_queue(), ^{ YUSQCTryInstall(attempt + 1); });
        else NSLog(@"[StageQuickCompanion] Dynamic Stage classes unavailable; left original unchanged.");
        return;
    }
    SEL select = @selector(collectionView:didSelectItemAtIndexPath:);
    SEL press = sel_registerName("handleLongPressGesture:");
    if (!YUSQCFromDynamicStage(list) || !YUSQCFromDynamicStage(cell) ||
        !YUSQCMethodMatches(class_getInstanceMethod(list, select), "v32@0:8@16@24") ||
        !YUSQCMethodMatches(class_getInstanceMethod(list, press), "v24@0:8@16") ||
        !YUSQCMethodMatches(class_getInstanceMethod(cell, sel_registerName(YUSQCCellApplication)), "@16@0:8")) {
        NSLog(@"[StageQuickCompanion] Unsupported Dynamic Stage build; left original unchanged.");
        return;
    }
    MSHookMessageEx(list, select, (IMP)YUSQCSelect, (IMP *)&YUSQCOriginalSelect);
    NSLog(@"[StageQuickCompanion] Installed Dynamic Stage app-tap adapter.");
}

__attribute__((constructor)) static void YUSQCInitialize(void) {
    dispatch_async(dispatch_get_main_queue(), ^{ YUSQCTryInstall(0); });
}
