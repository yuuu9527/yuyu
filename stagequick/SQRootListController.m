#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>
#import "StageQuickPreferences.h"

@interface SQRootListController : PSListController
@end

@implementation SQRootListController
- (NSMutableArray *)specifiers {
    if (!_specifiers) _specifiers = [[self loadSpecifiersFromPlistName:@"SQRoot" target:self] mutableCopy];
    return _specifiers;
}
- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    id value = SQNormalizedPreferences()[key] ?: [specifier propertyForKey:@"default"];
    if ([key isEqualToString:@"pinnedApplications"] && [value isKindOfClass:NSArray.class]) {
        return [value componentsJoinedByString:@", "];
    }
    return value;
}
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    id storedValue = value;
    if ([key isEqualToString:@"pinnedApplications"]) {
        NSMutableArray *items = [NSMutableArray array];
        for (NSString *item in [[value description] componentsSeparatedByString:@","]) {
            NSString *bundleID = [item stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
            if (bundleID.length && ![items containsObject:bundleID]) [items addObject:bundleID];
        }
        storedValue = items;
    }
    NSError *error = nil;
    if (!SQWritePreferences(@{key: storedValue ?: [NSNull null]}, &error)) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"设置未保存" message:error.localizedDescription ?: @"无法写入 StageQuick 设置。" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        [self reloadSpecifiers];
    }
}
@end
