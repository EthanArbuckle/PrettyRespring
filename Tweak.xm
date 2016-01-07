#import "prettyrespring.h"
#import "PRSnapshotter.h"

%hook SBUIController

- (id)init {

    //let backboardd send messages to this process, at callback function recoverFromPrettyRespring
    CFMessagePortRef port = CFMessagePortCreateLocal(kCFAllocatorDefault, CFSTR("com.ethanarbuckle.prettyrespring.backboard"), &recoverFromPrettyRespring, NULL, NULL);
    CFMessagePortSetDispatchQueue(port, dispatch_get_main_queue());

    return %orig;
}

- (void)finishLaunching {

    %orig;

    //sb is done loading, startup the thread to capture the screen
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PRSnapshotter *screenCapture = [[PRSnapshotter alloc] init];
        CADisplayLink *link = [CADisplayLink displayLinkWithTarget:screenCapture selector:@selector(captureScreen)];
        [link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        [[NSRunLoop currentRunLoop] run];
    });

}

CFDataRef recoverFromPrettyRespring(CFMessagePortRef local, SInt32 msgid, CFDataRef data, void *info) {

    //data is NSData representation of the springboard uiimage stored in backboardd
    NSData *imageData = [[NSData alloc] initWithData:(__bridge NSData *)data];
    if (![imageData isKindOfClass:[NSData class]]) {
        HBLogInfo(@"springboard received corrupt image data");
        return NULL;
    }

    //get uiimage from data
    UIImage *springboardSnap = [UIImage imageWithData:imageData];

    //create topmost window to cover lockscreen until we get to the homescreen
    UIWindow *frontWindow = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [frontWindow setWindowLevel:9999];
    [frontWindow makeKeyAndVisible];

    //add cached springboard image to window
    UIImageView *snapImage = [[UIImageView alloc] initWithFrame:[frontWindow frame]];
    [snapImage setImage:springboardSnap];
    [frontWindow addSubview:snapImage];

    //attempt to go straight to the homescreen
    NSDictionary *options = @{ @"SBUIUnlockOptionsNoPasscodeAnimationKey" : [NSNumber numberWithBool:YES],
                                @"SBUIUnlockOptionsBypassPasscodeKey" : [NSNumber numberWithBool:YES] };
    /*
    if ((r5 & 0xff) == 0x0) {
            r0 = r8->_disableLockScreenIfPossibleAssertions;
            r0 = [r0 count];
            if ((r6 & 0xff) != 0x0) {
                    CMP(r0, 0x0);
            }
    */  //I guess ill just add something fake to the lock assertions??
    NSString *openTheDoor = @"UNLOCK_PLZ";
    [[[objc_getClass("SBLockScreenManager") sharedInstance] valueForKey:@"_disableLockScreenIfPossibleAssertions"] addObject:openTheDoor];
    [[objc_getClass("SBLockScreenManager") sharedInstance] unlockUIFromSource:0xbeef withOptions:options];
    [[[objc_getClass("SBLockScreenManager") sharedInstance] valueForKey:@"_disableLockScreenIfPossibleAssertions"] removeObject:openTheDoor];

    //animate the window out
    [UIView animateWithDuration:1.5f animations:^{

        [frontWindow setAlpha:0.0];

    } completion:^(BOOL completed) {

        //at this point we're back home
        [frontWindow removeFromSuperview];

    }];

    return NULL;
}

%end

%hook SpringBoard

//these get released too early unless we put them outside of a methods scope
SBWorkspaceHomeScreenEntity *homescreenEntity;
SBMainWorkspaceTransitionRequest *transitionRequest;
SBWorkspaceDeactivatingEntity *deactivatingEntity;
SBWorkspaceApplicationTransitionContext *transitionContext;
SBAppToAppWorkspaceTransaction *transaction;

- (void)_relaunchSpringBoardNow {

    //put all the work into a block
    void (^prettyRespringBlock)() = ^{

        double delayInSeconds = 0.5f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {

            //snapshot the screen
            UIView *screenView = [[UIScreen mainScreen] snapshotViewAfterScreenUpdates:YES];
            [screenView setAlpha:0.1f];

            //create darkening view
            UIView *coverView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
            [coverView setBackgroundColor:[UIColor blackColor]];
            [coverView setAlpha:0.0f];
            [screenView addSubview:coverView];

            //create blur layer
            CAFilter *filter = [CAFilter filterWithType:@"gaussianBlur"];
            [filter setValue:[NSNumber numberWithFloat:3.0f] forKey:@"inputRadius"];
            [filter setValue:[NSNumber numberWithBool:YES] forKey:@"inputHardEdges"];

            //add the blur to the snapshots layer
            [[screenView layer] setFilters:@[filter]];
            [[screenView layer] setShouldRasterize:YES];

            // add the subview
            [[UIWindow keyWindow] addSubview:screenView];

            //begin the darkening/blurring animation
            [UIView animateWithDuration:1.5f delay:0 options:UIViewAnimationCurveEaseIn animations:^{

                [screenView setAlpha:1.0f];
                [coverView setAlpha:0.4f];

            } completion:^(BOOL completed) {

                if (completed) {

                    //dont want a big unblurred statusbar on the view
                    [[objc_getClass("SBAppStatusBarManager") sharedInstance] hideStatusBar];

                    //stop rasterizing now that animation is over
                    [[screenView layer] setShouldRasterize:NO];

                    //do respring
                    %orig;
                }
            }];
        });
    };

    //if an app is open, close to the homescreen
    if ([[UIApplication sharedApplication] _accessibilityFrontMostApplication]) {

        FBWorkspaceEvent *event = [NSClassFromString(@"FBWorkspaceEvent") eventWithName:@"ActivateSpringBoard" handler:^{

            SBDeactivationSettings *deactiveSets = [[NSClassFromString(@"SBDeactivationSettings") alloc] init];
            [deactiveSets setFlag:YES forDeactivationSetting:20];
            [deactiveSets setFlag:NO forDeactivationSetting:2];
            [[[UIApplication sharedApplication] _accessibilityFrontMostApplication] _setDeactivationSettings:deactiveSets];

            transitionContext = [[NSClassFromString(@"SBWorkspaceApplicationTransitionContext") alloc] init];

            //set layout role to 'side' (deactivating)
            deactivatingEntity = [NSClassFromString(@"SBWorkspaceDeactivatingEntity") entity];
            [deactivatingEntity setLayoutRole:3];
            [transitionContext setEntity:deactivatingEntity forLayoutRole:3];

            //set layout role for 'primary' (activating)
            homescreenEntity = [[NSClassFromString(@"SBWorkspaceHomeScreenEntity") alloc] init];
            [transitionContext setEntity:homescreenEntity forLayoutRole:2];

            //create transititon request
            transitionRequest = [[NSClassFromString(@"SBMainWorkspaceTransitionRequest") alloc] initWithDisplay:[[UIScreen mainScreen] valueForKey:@"_fbsDisplay"]];
            [transitionRequest setValue:transitionContext forKey:@"_applicationContext"];

            //create apptoapp transaction
            transaction = [[NSClassFromString(@"SBAppToAppWorkspaceTransaction") alloc] initWithTransitionRequest:transitionRequest];

            //i do the transaction manually so i can know exactly when its finished.
            //sbapptoappworkspacetransaction inherits '_completionBlock' from baseboard's BSTransaction
            [transaction setCompletionBlock:^{

                //do the pretty respring when the app finished closing
                prettyRespringBlock();
            }];

            //start closing
            [transaction begin];

        }];

        //all transactions need to be on an event queue
        FBWorkspaceEventQueue *transactionEventQueue = [NSClassFromString(@"FBWorkspaceEventQueue") sharedInstance];
        [transactionEventQueue executeOrAppendEvent:event];
    }

    else {

        //make sure we are on the first homescreen page
        [(SBRootFolderController *)[[objc_getClass("SBIconController") sharedInstance] valueForKey:@"_rootFolderController"] setCurrentPageIndex:0 animated:YES];

        //already on the homescreen, just pretty respring
        prettyRespringBlock();
    }
}

%end