#pragma once

#import <Preferences/PSListController.h>
#import "YsClockSliderCell.h"

@interface YsClock26RootListController : PSListController <YsClockSliderCellHandler>
- (void)applyAndRespring;
@end
