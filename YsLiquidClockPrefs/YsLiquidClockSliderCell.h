#pragma once

#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>
#include <math.h>

@protocol YsLiquidClockSliderCellHandler <NSObject>
- (double)ys_liquidclock_sliderValueForSpecifier:(PSSpecifier *)specifier;
- (void)ys_liquidclock_setSliderValue:(double)value specifier:(PSSpecifier *)specifier;
@end

@interface YsLiquidClockSliderCell : PSTableCell
@property (nonatomic, weak) id<YsLiquidClockSliderCellHandler> handler;
- (void)ys_liquidclock_reloadState;
@end
