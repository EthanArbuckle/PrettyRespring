#import <UIKit/UIKit.h>
#include <IOSurface/IOSurfaceAPI.h>
#include <dlfcn.h>
#include <objc/runtime.h>

@interface UIWindow (PrettyRespring)
+ (IOSurfaceRef)createScreenIOSurface;
+ (id)keyWindow;
@end

@interface PUIProgressWindow : UIWindow
@end

@interface BKSystemApplication : NSObject
-(id)bundleIdentifier;
@end

@interface SBLockScreenManager : NSObject
+ (id)sharedInstance;
- (void)unlockUIFromSource:(int)arg1 withOptions:(id)arg2;
- (BOOL)isUILocked;
@end

@interface SBIconController : NSObject
+ (id)sharedInstance;
@end

@interface SBRootFolderController : NSObject
- (BOOL)setCurrentPageIndex:(int)arg1 animated:(int)arg2;
@end

@interface SBAppStatusBarManager : NSObject
+ (id)sharedInstance;
- (void)hideStatusBar;
@end

@interface SBWorkspaceApplicationTransitionContext : NSObject
@property(nonatomic) _Bool animationDisabled; // @synthesize animationDisabled=_animationDisabled;
- (void)setEntity:(id)arg1 forLayoutRole:(int)arg2;
@end

@interface SBWorkspaceDeactivatingEntity : NSObject
@property(nonatomic) long long layoutRole; // @synthesize layoutRole=_layoutRole;
+ (id)entity;
@end

@interface SBWorkspaceHomeScreenEntity : NSObject
@end

@interface SBMainWorkspaceTransitionRequest : NSObject
- (id)initWithDisplay:(id)arg1;
@end

@interface SBAppToAppWorkspaceTransaction : NSObject
- (void)begin;
- (void)setCompletionBlock:(id)arg1;
- (void)transaction:(id)arg1 performTransitionWithCompletion:(id)arg2;
- (id)initWithAlertManager:(id)alertManager exitedApp:(id)app;
- (id)initWithAlertManager:(id)arg1 from:(id)arg2 to:(id)arg3 withResult:(id)arg4;
- (id)initWithTransitionRequest:(id)arg1;
@end

@interface FBWorkspaceEvent : NSObject
+ (instancetype)eventWithName:(NSString *)label handler:(id)handler;
@end

@interface FBWorkspaceEventQueue : NSObject
+ (instancetype)sharedInstance;
- (void)executeOrAppendEvent:(FBWorkspaceEvent *)event;
@end

@interface SBDeactivationSettings : NSObject
-(id)init;
-(void)setFlag:(int)flag forDeactivationSetting:(unsigned)deactivationSetting;
@end

@interface SBApplication : NSObject
@property(copy, nonatomic, setter=_setDeactivationSettings:) SBDeactivationSettings *_deactivationSettings;
- (void)setDeactivationSetting:(unsigned int)setting value:(id)value;
@end

@interface UIApplication (Private)
- (id)_accessibilityFrontMostApplication;
- (void)_relaunchSpringBoardNow;
@end

@interface CAFilter : NSObject
+ (id)filterWithType:(id)arg1;
@end

CFDataRef getImageFromSpringboard(CFMessagePortRef local, SInt32 msgid, CFDataRef data, void *info);
CFDataRef recoverFromPrettyRespring(CFMessagePortRef local, SInt32 msgid, CFDataRef data, void *info);

typedef void* (*SYM_CARenderServerRenderDisplay)(kern_return_t a, CFStringRef b, IOSurfaceRef surface, int x, int y);

static SYM_CARenderServerRenderDisplay CARenderServerRenderDisplay;