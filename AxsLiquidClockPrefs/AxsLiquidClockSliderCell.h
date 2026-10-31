#pragma once

#import <Preferences/PSTableCell.h>
#import <Preferences/PSSpecifier.h>
#include <math.h>

@protocol AxsLiquidClockSliderCellHandler <NSObject>
- (double)axs_liquidclock_sliderValueForSpecifier:(PSSpecifier *)specifier;
- (void)axs_liquidclock_setSliderValue:(double)value specifier:(PSSpecifier *)specifier;
@end

@interface AxsLiquidClockSliderCell : PSTableCell
@property (nonatomic, weak) id<AxsLiquidClockSliderCellHandler> handler;
- (void)axs_liquidclock_reloadState;
@end
