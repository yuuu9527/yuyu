#pragma once

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

#ifdef THEOS_PACKAGE_SCHEME_ROOTHIDE
#import <roothide.h>
#endif

static NSString * const SQPreferencesDomain = @"com.yu.stagequick";
static NSString * const SQPreferencesChangedNotification = @"com.yu.stagequick.preferences-changed";
static NSString * const SQPreferencesPath = @"/var/mobile/Library/Preferences/com.yu.stagequick.plist";

static inline NSString *SQPreferencesResolvedPath(void) {
#ifdef THEOS_PACKAGE_SCHEME_ROOTHIDE
    return jbroot(SQPreferencesPath);
#else
    return SQPreferencesPath;
#endif
}

static inline NSDictionary *SQPreferencesDefaults(void) {
    return @{ @"enabled": @YES,
              @"openMode": @"Original",
              @"pinnedApplications": @[],
              @"appearance": @"System" };
}

static inline NSDictionary *SQReadPreferences(void) {
    NSDictionary *values = [NSDictionary dictionaryWithContentsOfFile:SQPreferencesResolvedPath()];
    if ([values isKindOfClass:NSDictionary.class]) return values;
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:SQPreferencesDomain];
    NSDictionary *domain = [defaults persistentDomainForName:SQPreferencesDomain];
    return [domain isKindOfClass:NSDictionary.class] ? domain : @{};
}

static inline NSDictionary *SQNormalizedPreferences(void) {
    NSMutableDictionary *result = [SQPreferencesDefaults() mutableCopy];
    NSDictionary *values = SQReadPreferences();
    id enabled = values[@"enabled"];
    id mode = values[@"openMode"];
    id pinned = values[@"pinnedApplications"];
    id appearance = values[@"appearance"];
    if ([enabled respondsToSelector:@selector(boolValue)]) result[@"enabled"] = @([enabled boolValue]);
    if ([mode isKindOfClass:NSString.class] && [@[ @"Original", @"Fullscreen", @"Combination" ] containsObject:mode]) result[@"openMode"] = mode;
    if ([pinned isKindOfClass:NSArray.class]) result[@"pinnedApplications"] = pinned;
    if ([appearance isKindOfClass:NSString.class] && [@[ @"System", @"Light", @"Dark" ] containsObject:appearance]) result[@"appearance"] = appearance;
    return result;
}

static inline NSDictionary *SQSanitizedPreferences(NSDictionary *values) {
    NSMutableDictionary *result = [SQPreferencesDefaults() mutableCopy];
    id enabled = values[@"enabled"];
    id mode = values[@"openMode"];
    id pinned = values[@"pinnedApplications"];
    id appearance = values[@"appearance"];
    if ([enabled respondsToSelector:@selector(boolValue)]) result[@"enabled"] = @([enabled boolValue]);
    if ([mode isKindOfClass:NSString.class] && [@[ @"Original", @"Fullscreen", @"Combination" ] containsObject:mode]) result[@"openMode"] = mode;
    if ([pinned isKindOfClass:NSArray.class]) result[@"pinnedApplications"] = pinned;
    if ([appearance isKindOfClass:NSString.class] && [@[ @"System", @"Light", @"Dark" ] containsObject:appearance]) result[@"appearance"] = appearance;
    return result;
}

static inline BOOL SQWritePreferences(NSDictionary *changes, NSError **error) {
    NSString *path = SQPreferencesResolvedPath();
    NSFileManager *fm = NSFileManager.defaultManager;
    NSMutableDictionary *values = [SQReadPreferences() mutableCopy];
    if (![values isKindOfClass:NSMutableDictionary.class]) values = [NSMutableDictionary dictionary];
    [values addEntriesFromDictionary:changes];
    values = [SQSanitizedPreferences(values) mutableCopy];
    NSData *data = [NSPropertyListSerialization dataWithPropertyList:values format:NSPropertyListBinaryFormat_v1_0 options:0 error:error];
    if (!data || ![fm createDirectoryAtPath:path.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:error]) return NO;
    if (![data writeToFile:path options:NSDataWritingAtomic error:error]) return NO;
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:SQPreferencesDomain];
    [defaults setPersistentDomain:values forName:SQPreferencesDomain];
    [defaults synchronize];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)SQPreferencesChangedNotification, NULL, NULL, true);
    return YES;
}
