#import "YsClock26RootListController.h"

#import <Preferences/PSSpecifier.h>
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <spawn.h>
#import <unistd.h>

extern char **environ;

static NSString * const kYsClockDomain = @"dylv.liquidassprefs";
static NSString * const kYsClockReload = @"dylv.liquidassprefs/Reload";

static NSString *YsClockPrefsPath(void) {
    // 引擎按这个真实路径读取（roothide 下同样落在 /var/mobile），不随 jbroot 变化。
    return @"/var/mobile/Library/Preferences/dylv.liquidassprefs.plist";
}

static NSMutableDictionary *YsClockCurrentValues(void) {
    NSDictionary *values = [NSDictionary dictionaryWithContentsOfFile:YsClockPrefsPath()];
    if ([values isKindOfClass:[NSDictionary class]]) return [values mutableCopy];
    // 文件还不存在时退回 cfprefsd 的快照，避免第一次写入丢键。
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kYsClockDomain];
    [defaults synchronize];
    NSDictionary *persisted = [defaults persistentDomainForName:kYsClockDomain];
    return [persisted isKindOfClass:[NSDictionary class]] ? [persisted mutableCopy]
                                                          : [NSMutableDictionary dictionary];
}

static id YsClockReadValue(NSString *key) {
    if (key.length == 0) return nil;
    return YsClockCurrentValues()[key];
}

static void YsClockWriteValue(NSString *key, id value) {
    if (key.length == 0) return;
    NSMutableDictionary *values = YsClockCurrentValues();
    if (value) values[key] = value;
    else [values removeObjectForKey:key];

    NSData *data = [NSPropertyListSerialization dataWithPropertyList:values
                                                              format:NSPropertyListBinaryFormat_v1_0
                                                             options:0
                                                               error:NULL];
    if (data) [data writeToFile:YsClockPrefsPath() options:NSDataWritingAtomic error:NULL];

    // 把整份快照镜像给 cfprefsd，防止它之后用旧值覆盖刚写进去的文件。
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kYsClockDomain];
    [defaults setPersistentDomain:values forName:kYsClockDomain];
    [defaults synchronize];

    // 引擎监听这个通知做热刷新，注销后再读一次以覆盖冷启动路径。
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         (__bridge CFStringRef)kYsClockReload,
                                         NULL, NULL, true);
}

static BOOL YsClockSpawnKillall(NSString *path) {
    if (![[NSFileManager defaultManager] isExecutableFileAtPath:path]) return NO;
    pid_t pid = 0;
    char *argv[] = { (char *)path.fileSystemRepresentation, (char *)"-9",
                     (char *)"SpringBoard", NULL };
    int rc = posix_spawn(&pid, path.fileSystemRepresentation, NULL, NULL, argv, environ);
    return rc == 0;
}

@implementation YsClock26RootListController

- (NSMutableArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"YsClock26Root" target:self] mutableCopy];
    }
    return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    id value = YsClockReadValue([specifier propertyForKey:@"key"]);
    return value ?: [specifier propertyForKey:@"default"];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    YsClockWriteValue([specifier propertyForKey:@"key"], value);
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell
    forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([PSListController instancesRespondToSelector:_cmd]) {
        [super tableView:tableView willDisplayCell:cell forRowAtIndexPath:indexPath];
    }
    if ([cell isKindOfClass:[YsClockSliderCell class]]) {
        YsClockSliderCell *sliderCell = (YsClockSliderCell *)cell;
        sliderCell.handler = self;
        [sliderCell ys_clock_reloadState];
    }
}

#pragma mark - slider

- (double)ys_clock_sliderValueForSpecifier:(PSSpecifier *)specifier {
    id value = [self readPreferenceValue:specifier];
    return [value isKindOfClass:[NSNumber class]] ? [value doubleValue] : 0.0;
}

- (void)ys_clock_setSliderValue:(double)value specifier:(PSSpecifier *)specifier {
    double minimum = [[specifier propertyForKey:@"min"] doubleValue];
    double maximum = [[specifier propertyForKey:@"max"] doubleValue];
    if (!isfinite(minimum)) minimum = 0.0;
    if (!isfinite(maximum) || maximum <= minimum) maximum = minimum + 1.0;
    if (!isfinite(value)) value = minimum;
    double clamped = fmax(minimum, fmin(maximum, value));
    if ([[specifier propertyForKey:@"integer"] boolValue]) {
        [self setPreferenceValue:@((int)lround(clamped)) specifier:specifier];
    } else {
        [self setPreferenceValue:@(clamped) specifier:specifier];
    }
}

#pragma mark - actions

- (void)applyAndRespring {
    [[[NSUserDefaults alloc] initWithSuiteName:kYsClockDomain] synchronize];
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         (__bridge CFStringRef)kYsClockReload,
                                         NULL, NULL, true);

    NSArray<NSString *> *candidates = @[
        @"/var/jb/usr/bin/killall",
        @"/var/jb/basebin/killall",
        @"/usr/bin/killall",
        @"/bin/killall"
    ];
    for (NSString *path in candidates) {
        if (YsClockSpawnKillall(path)) return;
    }

    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"设置已保存"
                         message:@"没找到 killall 命令，无法自动注销，请手动注销设备后生效。"
                  preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"好"
                                              style:UIAlertActionStyleDefault
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
