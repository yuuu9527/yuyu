#pragma once

#import <Foundation/Foundation.h>

@interface YuDynamicstagepanConfig : NSObject
+ (instancetype)yu_dynamicstagepan_shared;
- (BOOL)yu_dynamicstagepan_isEnabled;
- (id)yu_dynamicstagepan_valueForKey:(NSString *)key defaultValue:(id)defaultValue;
- (void)yu_dynamicstagepan_reload;
@end
