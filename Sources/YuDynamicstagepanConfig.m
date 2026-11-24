#import "YuDynamicstagepanConfig.h"
#import "YuDynamicstagepanPreferences.h"

@interface YuDynamicstagepanConfig ()
@property (atomic, copy) NSDictionary *snapshot;
@property (nonatomic, strong) dispatch_queue_t reloadQueue;
@end

static void yu_dynamicstagepan_preferencesDidChange(CFNotificationCenterRef center, void *observer,
                                          CFStringRef name, const void *object, CFDictionaryRef info) {
    YuDynamicstagepanConfig *config = (__bridge YuDynamicstagepanConfig *)observer;
    dispatch_async(config.reloadQueue, ^{
        [config yu_dynamicstagepan_reload];
    });
}

@implementation YuDynamicstagepanConfig

+ (instancetype)yu_dynamicstagepan_shared {
    static YuDynamicstagepanConfig *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _reloadQueue = dispatch_queue_create("com.yu.dynamicstagepan.preferences", DISPATCH_QUEUE_SERIAL);
        [self yu_dynamicstagepan_reload];
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
            (__bridge const void *)self, yu_dynamicstagepan_preferencesDidChange,
            (__bridge CFStringRef)YuDynamicstagepanPreferencesChanged, NULL,
            CFNotificationSuspensionBehaviorDeliverImmediately);
        // Close the window between the first read and observer registration.
        dispatch_async(_reloadQueue, ^{ [self yu_dynamicstagepan_reload]; });
    }
    return self;
}

- (void)yu_dynamicstagepan_reload {
    self.snapshot = yu_dynamicstagepan_readPreferences();
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:YuDynamicstagepanPreferencesChanged object:self];
    });
}

- (id)yu_dynamicstagepan_valueForKey:(NSString *)key defaultValue:(id)defaultValue {
    return self.snapshot[key] ?: defaultValue;
}

- (BOOL)yu_dynamicstagepan_isEnabled {
    id value = [self yu_dynamicstagepan_valueForKey:@"enabled" defaultValue:@(YES)];
    return [value isKindOfClass:[NSNumber class]] ? [value boolValue] : YES;
}

- (void)dealloc {
    CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                            (__bridge const void *)self);
}

@end
