#pragma once

#import <UIKit/UIKit.h>

// 只声明插件实际用到的两个锁屏承载类，不声明未确认的私有方法。
// 注入点仍需按目标 iOS 版本在真机验证。

@interface SBFLockScreenDateView : UIView
@end

@interface SBFLockScreenDateViewController : UIViewController
@end
