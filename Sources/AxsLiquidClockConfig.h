#pragma once

#import <Foundation/Foundation.h>

@interface AxsLiquidClockConfig : NSObject
+ (instancetype)axs_liquidclock_shared;
- (BOOL)axs_liquidclock_isEnabled;
- (id)axs_liquidclock_valueForKey:(NSString *)key defaultValue:(id)defaultValue;
- (void)axs_liquidclock_reload;
@end
