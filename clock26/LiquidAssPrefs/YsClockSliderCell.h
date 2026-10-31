#pragma once

#import <Preferences/Preferences.h>
#import <UIKit/UIKit.h>
#include <math.h>

@protocol YsClockSliderCellHandler <NSObject>
- (double)ys_clock_sliderValueForSpecifier:(PSSpecifier *)specifier;
- (void)ys_clock_setSliderValue:(double)value specifier:(PSSpecifier *)specifier;
@end

@interface YsClockSliderCell : PSTableCell
@property (nonatomic, weak) id<YsClockSliderCellHandler> handler;
- (void)ys_clock_reloadState;
@end
