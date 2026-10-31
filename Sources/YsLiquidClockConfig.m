#import "YsLiquidClockConfig.h"
#import "YsLiquidClockPreferences.h"

@interface YsLiquidClockConfig ()
@property (atomic, copy) NSDictionary *snapshot;
@property (nonatomic, strong) dispatch_queue_t reloadQueue;
@end

static void ys_liquidclock_preferencesDidChange(CFNotificationCenterRef center, void *observer,
                                          CFStringRef name, const void *object, CFDictionaryRef info) {
    YsLiquidClockConfig *config = (__bridge YsLiquidClockConfig *)observer;
    dispatch_async(config.reloadQueue, ^{
        [config ys_liquidclock_reload];
    });
}

@implementation YsLiquidClockConfig

+ (instancetype)ys_liquidclock_shared {
    static YsLiquidClockConfig *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _reloadQueue = dispatch_queue_create("com.ys.liquidclock.preferences", DISPATCH_QUEUE_SERIAL);
        [self ys_liquidclock_reload];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)self, ys_liquidclock_preferencesDidChange,
            (__bridge CFStringRef)YsLiquidClockPreferencesChanged, NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately);
        // Close the window between the first read and observer registration.
        dispatch_async(_reloadQueue, ^{ [self ys_liquidclock_reload]; });
    }
    return self;
}

- (void)ys_liquidclock_reload {
    self.snapshot = ys_liquidclock_readPreferences();
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:YsLiquidClockPreferencesChanged object:self];
    });
}

- (id)ys_liquidclock_valueForKey:(NSString *)key defaultValue:(id)defaultValue {
    return self.snapshot[key] ?: defaultValue;
}

- (BOOL)ys_liquidclock_isEnabled {
    id value = [self ys_liquidclock_valueForKey:@"enabled" defaultValue:@(NO)];
    return [value isKindOfClass:[NSNumber class]] ? [value boolValue] : NO;
}

- (void)dealloc {
    CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                            (__bridge const void *)self);
}

@end
