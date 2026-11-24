#import <UIKit/UIKit.h>
#import "YuDynamicstagepanConfig.h"
#import "YuDynamicstagepanPrivate.h"
#include <dlfcn.h>

// This sample matches the default SpringBoard filter. Replace both together.
%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    if (![[YuDynamicstagepanConfig yu_dynamicstagepan_shared] yu_dynamicstagepan_isEnabled]) {
        return;
    }
    // Plugin loads its dylibs at initialization
}

%end

%ctor {
    @autoreleasepool {
        // Readers load a snapshot; they never write default preferences.
        [YuDynamicstagepanConfig yu_dynamicstagepan_shared];
        
        // Load precompiled dylibs
        NSBundle *bundle = [NSBundle bundleWithPath:@"/Library/PreferenceBundles/YuDynamicstagepan.bundle"];
        if (bundle) {
            NSString *bundlePath = [bundle bundlePath];
            NSString *dylib1Path = [bundlePath stringByAppendingPathComponent:@"DynamicStage.dylib"];
            NSString *dylib2Path = [bundlePath stringByAppendingPathComponent:@"StageDaemon.dylib"];
            
            // Load DynamicStage.dylib
            if ([[NSFileManager defaultManager] fileExistsAtPath:dylib1Path]) {
                dlopen([dylib1Path UTF8String], RTLD_NOW);
            }
            
            // Load StageDaemon.dylib  
            if ([[NSFileManager defaultManager] fileExistsAtPath:dylib2Path]) {
                dlopen([dylib2Path UTF8String], RTLD_NOW);
            }
        }
    }
}

minis_url: minis://shared/DynamicStage-panels/trigger-panel-theos/Hooks/YuDynamicstagepanMain.xm
