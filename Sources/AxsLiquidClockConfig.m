#import "AxsLiquidClockConfig.h"
#import "AxsLiquidClockPreferences.h"

@interface AxsLiquidClockConfig ()
@property (atomic, copy) NSDictionary *snapshot;
@property (nonatomic, strong) dispatch_queue_t reloadQueue;
@end

static void axs_liquidclock_preferencesDidChange(CFNotificationCenterRef center, void *observer,
                                          CFStringRef name, const void *object, CFDictionaryRef info) {
    AxsLiquidClockConfig *config = (__bridge AxsLiquidClockConfig *)observer;
    dispatch_async(config.reloadQueue, ^{
        [config axs_liquidclock_reload];
    });
}

@implementation AxsLiquidClockConfig

+ (instancetype)axs_liquidclock_shared {
    static AxsLiquidClockConfig *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _reloadQueue = dispatch_queue_create("com.axs.liquidclock.preferences", DISPATCH_QUEUE_SERIAL);
        [self axs_liquidclock_reload];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)self, axs_liquidclock_preferencesDidChange,
            (__bridge CFStringRef)AxsLiquidClockPreferencesChanged, NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately);
        // Close the window between the first read and observer registration.
        dispatch_async(_reloadQueue, ^{ [self axs_liquidclock_reload]; });
    }
    return self;
}

- (void)axs_liquidclock_reload {
    self.snapshot = axs_liquidclock_readPreferences();
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:AxsLiquidClockPreferencesChanged object:self];
    });
}

- (id)axs_liquidclock_valueForKey:(NSString *)key defaultValue:(id)defaultValue {
    return self.snapshot[key] ?: defaultValue;
}

- (BOOL)axs_liquidclock_isEnabled {
    id value = [self axs_liquidclock_valueForKey:@"enabled" defaultValue:@(NO)];
    return [value isKindOfClass:[NSNumber class]] ? [value boolValue] : NO;
}

- (void)dealloc {
    CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                            (__bridge const void *)self);
}

@end
