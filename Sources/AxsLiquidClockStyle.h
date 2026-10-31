#pragma once

#import <UIKit/UIKit.h>

// 读取配置快照并给出锁屏时钟的字体/发光参数。
// 高频调用方只读快照，不写配置、不扫目录。
@interface AxsLiquidClockStyle : NSObject

+ (instancetype)axs_liquidclock_style;

- (BOOL)axs_liquidclock_isEnabled;
- (UIFont *)axs_liquidclock_fontForBaseFont:(UIFont *)baseFont;

// 启用时套用样式，关闭时还原首次记录的原字体。
- (void)axs_liquidclock_applyToLabel:(UILabel *)label;

@end
