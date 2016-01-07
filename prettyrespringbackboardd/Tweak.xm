#import "../prettyrespring.h"
#import "PRImageContainer.h"

%hook BKSystemAppSentinel

- (void)startSystemAppCheckInServer {

    %orig;

    //create a server that receives messages from springboard and sends them to 'getImageFromSpringboard'
    CFMessagePortRef port = CFMessagePortCreateLocal(kCFAllocatorDefault, CFSTR("com.ethanarbuckle.prettyrespring"), &getImageFromSpringboard, NULL, NULL);
    CFMessagePortSetDispatchQueue(port, dispatch_get_main_queue());
}

//this gets hit a few seconds before springboard gets created
- (void)server:(id)server systemAppCheckedIn:(BKSystemApplication *)application completion:(void (^)())complete {

    //completion block so we run after SB
    void (^newCompletion)() = ^{

        //do original completion first
        complete();

        //confirm this system app is springboard
        if ([[application bundleIdentifier] isEqualToString:@"com.apple.springboard"]) {

            //recoveringFromPrettyRespring == 1 and having an image of SB means we're finishing the transition back to HS
            UIImage *springboardImage = [[PRImageContainer sharedInstance] getSpringboardImage];
            if ([[PRImageContainer sharedInstance] recoveringFromPrettyRespring] && springboardImage) {

                //we need to ensure SB is already done loading before we create remote server to it
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{

                    //connect remote to SB
                    CFMessagePortRef port = CFMessagePortCreateRemote(kCFAllocatorDefault, CFSTR("com.ethanarbuckle.prettyrespring.backboard"));
                    if (port > 0) {

                        //get NSData representation of the cached SB image
                        NSData *imageData = UIImagePNGRepresentation(springboardImage);

                        //send the image back to springboard
                        SInt32 req = CFMessagePortSendRequest(port, 0, (CFDataRef)imageData, 1000, 0, NULL, NULL);
                        if (req != kCFMessagePortSuccess) {

                            HBLogInfo(@"error with message request from backboardd to springboard");
                        }

                        //close connection
                        CFMessagePortInvalidate(port);

                    }

                    else {

                        HBLogInfo(@"error, failed to create remote server: %s", strerror(errno));
                    }

                    //reset our flag so we dont do it again unwarrented
                    [[PRImageContainer sharedInstance] setRecoveringFromPrettyRespring:NO];

                });
            }
        }

        else {

            HBLogInfo(@"checked in system app is not springboard");
        }

    };

    %orig(server, application, newCompletion);
}

CFDataRef getImageFromSpringboard(CFMessagePortRef local, SInt32 msgid, CFDataRef data, void *info) {

    //create and store image from received data
    [[PRImageContainer sharedInstance] setSpringboardImage:(__bridge NSData *)data];

    return NULL;
}

%end

//this is the respring iosurface
%hook PUIProgressWindow

//normally, arg1 would be "apple-logo-xx", I zero them out since we dont need it
- (id)_createImageWithName:(const char *)arg1 scale:(int)arg2 displayHeight:(int)arg3 {

    UIImage *springboardImage = [[PRImageContainer sharedInstance] getSpringboardImage];
    if (springboardImage) {

        //get main layer of surface, and add image onto it
        CALayer *surfaceLayer = [self valueForKey:@"_layer"];
        UIImageView *springImageView = [[UIImageView alloc] initWithFrame:[surfaceLayer frame]];
        [springImageView setImage:springboardImage];
        [surfaceLayer addSublayer:[springImageView layer]];

        //set flag so we can do a pretty recovery
        [[PRImageContainer sharedInstance] setRecoveringFromPrettyRespring:YES];

        //call original function, void of the apple logo layer
        return %orig("", 0, 0);
    }

    //normal boot or respring
    return %orig;

}

%end