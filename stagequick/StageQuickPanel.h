#pragma once
#import <UIKit/UIKit.h>
#ifdef __cplusplus
extern "C" {
#endif
void YUStageQuickShow(void);
void YUStageQuickDismiss(void);
void YUStageQuickSetProgress(CGFloat progress);
void YUStageQuickFinish(BOOL opened);
#ifdef __cplusplus
}
#endif
