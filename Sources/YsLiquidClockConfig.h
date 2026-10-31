#pragma once

#import <Foundation/Foundation.h>

@interface YsLiquidClockConfig : NSObject
+ (instancetype)ys_liquidclock_shared;
- (BOOL)ys_liquidclock_isEnabled;
- (id)ys_liquidclock_valueForKey:(NSString *)key defaultValue:(id)defaultValue;
- (void)ys_liquidclock_reload;
@end
