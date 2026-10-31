#import "AxsLiquidClockStyle.h"
#import "AxsLiquidClockConfig.h"
#import <CoreText/CoreText.h>
#import <objc/runtime.h>
#import <math.h>

static const void *AxsLiquidClockOriginalFontKey = &AxsLiquidClockOriginalFontKey;
static const void *AxsLiquidClockAppliedKey = &AxsLiquidClockAppliedKey;

static double axs_liquidclock_clamp(double value, double minimum, double maximum) {
    if (!isfinite(value)) return minimum;
    return fmax(minimum, fmin(maximum, value));
}

// 液态数字字体来自已安装的 LiquidAss 资源包；找不到就退回系统字体，不打包他人资源。
static NSString *axs_liquidclock_externalFontPath(void) {
    static NSString *cachedPath;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray<NSString *> *candidates = @[
            @"/var/jb/Library/PreferenceBundles/LiquidAssPrefs.bundle/SFAdaptiveSoftNumeric-VF.otf",
            @"/Library/PreferenceBundles/LiquidAssPrefs.bundle/SFAdaptiveSoftNumeric-VF.otf",
            @"/var/jb/Library/PreferenceBundles/YuLiquidClockPrefs.bundle/SFAdaptiveSoftNumeric-VF.otf",
            @"/Library/PreferenceBundles/YuLiquidClockPrefs.bundle/SFAdaptiveSoftNumeric-VF.otf",
        ];
        NSFileManager *manager = [NSFileManager defaultManager];
        for (NSString *path in candidates) {
            if ([manager fileExistsAtPath:path]) {
                cachedPath = path;
                break;
            }
        }
    });
    return cachedPath;
}

static NSString *axs_liquidclock_externalFontName(void) {
    static NSString *cachedName;
    static BOOL resolved;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        resolved = YES;
        NSString *path = axs_liquidclock_externalFontPath();
        if (path.length == 0) return;
        NSURL *url = [NSURL fileURLWithPath:path];
        CFErrorRef error = NULL;
        // 只注册到本进程，不影响系统字体表。
        if (!CTFontManagerRegisterFontsForURL((__bridge CFURLRef)url,
                                             kCTFontManagerScopeProcess, &error)) {
            if (error) CFRelease(error);
        }
        NSDictionary *attributes = @{(__bridge NSString *)kCTFontURLAttribute: url};
        CTFontDescriptorRef descriptor = CTFontDescriptorCreateWithAttributes(
            (__bridge CFDictionaryRef)attributes);
        if (!descriptor) return;
        CTFontRef font = CTFontCreateWithFontDescriptor(descriptor, 12.0, NULL);
        CFRelease(descriptor);
        if (!font) return;
        CFStringRef name = CTFontCopyPostScriptName(font);
        CFRelease(font);
        if (name) {
            cachedName = [(__bridge NSString *)name copy];
            CFRelease(name);
        }
    });
    return resolved ? cachedName : nil;
}

@implementation AxsLiquidClockStyle

+ (instancetype)axs_liquidclock_style {
    static AxsLiquidClockStyle *style;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        style = [[self alloc] init];
    });
    return style;
}

- (id)axs_liquidclock_valueForKey:(NSString *)key defaultValue:(id)defaultValue {
    return [[AxsLiquidClockConfig axs_liquidclock_shared] axs_liquidclock_valueForKey:key
                                                                        defaultValue:defaultValue];
}

- (double)axs_liquidclock_doubleForKey:(NSString *)key
                              fallback:(double)fallback
                               minimum:(double)minimum
                               maximum:(double)maximum {
    id value = [self axs_liquidclock_valueForKey:key defaultValue:@(fallback)];
    double number = [value isKindOfClass:[NSNumber class]] ? [value doubleValue] : fallback;
    return axs_liquidclock_clamp(number, minimum, maximum);
}

- (BOOL)axs_liquidclock_isEnabled {
    id value = [self axs_liquidclock_valueForKey:@"enabled" defaultValue:@(NO)];
    return [value isKindOfClass:[NSNumber class]] ? [value boolValue] : NO;
}

- (double)axs_liquidclock_scale {
    return [self axs_liquidclock_doubleForKey:@"clockScale" fallback:1.2 minimum:0.8 maximum:2.0];
}

// 面板用 0~10 的滑条，消费端换算为 0~1 的字重系数。
- (double)axs_liquidclock_weightRatio {
    return [self axs_liquidclock_doubleForKey:@"clockWeight" fallback:6.2 minimum:0.0 maximum:10.0] / 10.0;
}

- (BOOL)axs_liquidclock_isRounded {
    id value = [self axs_liquidclock_valueForKey:@"roundedFont" defaultValue:@(YES)];
    return [value isKindOfClass:[NSNumber class]] ? [value boolValue] : YES;
}

- (BOOL)axs_liquidclock_usesLiquidFont {
    id value = [self axs_liquidclock_valueForKey:@"liquidFont" defaultValue:@(YES)];
    return [value isKindOfClass:[NSNumber class]] ? [value boolValue] : YES;
}

- (double)axs_liquidclock_glow {
    return [self axs_liquidclock_doubleForKey:@"glowStrength" fallback:0.35 minimum:0.0 maximum:1.0];
}

- (double)axs_liquidclock_tracking {
    return [self axs_liquidclock_doubleForKey:@"letterSpacing" fallback:0.0 minimum:-2.0 maximum:2.0];
}

- (UIFont *)axs_liquidclock_fontForBaseFont:(UIFont *)baseFont {
    UIFont *base = [baseFont isKindOfClass:[UIFont class]]
        ? baseFont
        : [UIFont systemFontOfSize:72.0 weight:UIFontWeightSemibold];
    CGFloat size = MAX(10.0, round(base.pointSize * [self axs_liquidclock_scale]));
    CGFloat weight = UIFontWeightRegular +
        [self axs_liquidclock_weightRatio] * (UIFontWeightBlack - UIFontWeightRegular);

    if ([self axs_liquidclock_usesLiquidFont]) {
        NSString *name = axs_liquidclock_externalFontName();
        if (name.length > 0) {
            UIFont *liquid = [UIFont fontWithName:name size:size];
            if (liquid) return liquid;
        }
    }

    UIFontDescriptor *descriptor = nil;
    if ([self axs_liquidclock_isRounded]) {
        UIFont *system = [UIFont systemFontOfSize:size weight:weight];
        descriptor = [system.fontDescriptor fontDescriptorWithDesign:UIFontDescriptorSystemDesignRounded];
    } else {
        descriptor = [base.fontDescriptor fontDescriptorWithSize:size];
        if (descriptor) {
            descriptor = [descriptor fontDescriptorByAddingAttributes:
                @{UIFontDescriptorTraitsAttribute: @{UIFontWeightTrait: @(weight)}}];
        }
    }
    UIFont *font = descriptor ? [UIFont fontWithDescriptor:descriptor size:size] : nil;
    return font ?: [UIFont systemFontOfSize:size weight:weight];
}

- (void)axs_liquidclock_applyToLabel:(UILabel *)label {
    if (![label isKindOfClass:[UILabel class]]) return;

    UIFont *original = objc_getAssociatedObject(label, AxsLiquidClockOriginalFontKey);
    if (![self axs_liquidclock_isEnabled]) {
        if (original) {
            label.font = original;
            objc_setAssociatedObject(label, AxsLiquidClockOriginalFontKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(label, AxsLiquidClockAppliedKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
            label.layer.shadowOpacity = 0.0f;
            label.layer.shadowRadius = 0.0f;
        }
        return;
    }

    if (!original) {
        // 只在第一次套用时记录原字体，后续重算都以它为基准，避免逐次叠加。
        objc_setAssociatedObject(label, AxsLiquidClockOriginalFontKey, label.font,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        original = label.font;
    }

    UIFont *base = [original isKindOfClass:[UIFont class]] ? original : label.font;
    NSString *signature = [NSString stringWithFormat:@"%@|%@|%.2f|%.2f|%.2f|%.2f|%ld|%ld|%.2f",
        base.fontName, label.text ?: @"",
        base.pointSize, [self axs_liquidclock_scale], [self axs_liquidclock_weightRatio],
        [self axs_liquidclock_tracking],
        (long)([self axs_liquidclock_isRounded] ? 1 : 0),
        (long)([self axs_liquidclock_usesLiquidFont] ? 1 : 0),
        [self axs_liquidclock_glow]];
    if ([objc_getAssociatedObject(label, AxsLiquidClockAppliedKey) isEqual:signature]) return;
    objc_setAssociatedObject(label, AxsLiquidClockAppliedKey, signature, OBJC_ASSOCIATION_COPY_NONATOMIC);

    UIFont *font = [self axs_liquidclock_fontForBaseFont:base];
    label.font = font;

    double tracking = [self axs_liquidclock_tracking];
    if (fabs(tracking) > 0.001 && label.text.length > 0) {
        label.attributedText = [[NSAttributedString alloc] initWithString:label.text
            attributes:@{NSKernAttributeName: @(tracking), NSFontAttributeName: font}];
    }

    double glow = [self axs_liquidclock_glow];
    CALayer *layer = label.layer;
    if (glow > 0.0) {
        // 白色柔光模拟液态玻璃的边缘折射，不能裁切到 label 边界内。
        layer.masksToBounds = NO;
        layer.shadowColor = [UIColor whiteColor].CGColor;
        layer.shadowOpacity = (float)(0.85 * glow);
        layer.shadowRadius = MAX(1.0, font.pointSize * 0.05);
        layer.shadowOffset = CGSizeZero;
    } else {
        layer.shadowOpacity = 0.0f;
        layer.shadowRadius = 0.0f;
    }
}

@end
