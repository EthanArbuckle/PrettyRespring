#import "PRSnapshotter.h"

@implementation PRSnapshotter

- (id)init {

    if ((self = [super init])) {

        //create iosurface
        _screenSurface = [UIWindow createScreenIOSurface];
        if (!_screenSurface) {

            HBLogInfo(@"Failed to create surface");
        }

        //can never find symbol for carenderserverdisplay
        void *handle = dlopen(0, 9);
        *(void**)(&CARenderServerRenderDisplay) = dlsym(handle,"CARenderServerRenderDisplay");

        _messagingPort = CFMessagePortCreateRemote(kCFAllocatorDefault, CFSTR("com.ethanarbuckle.prettyrespring"));
        if (_messagingPort < 0) {
            HBLogInfo(@"error creating _messagingPort port %s", strerror(errno));
        }

    }

    return self;
}

- (void)captureScreen {

    IOSurfaceLock(_screenSurface, 0, nil);

    CARenderServerRenderDisplay(0, CFSTR("LCD"), _screenSurface, 0, 0);

    IOSurfaceUnlock(_screenSurface, 0, 0);

    void *base = IOSurfaceGetBaseAddress(_screenSurface);
    int totalBytes = IOSurfaceGetBytesPerRow(_screenSurface) * IOSurfaceGetHeight(_screenSurface);

    NSMutableData *data = [NSMutableData dataWithBytes:base length:totalBytes];
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, [data bytes], [data length], NULL);
    CGImageRef coreImage = CGImageCreate(IOSurfaceGetWidth(_screenSurface), IOSurfaceGetHeight(_screenSurface), 8, 32, IOSurfaceGetBytesPerRow(_screenSurface), CGColorSpaceCreateDeviceRGB(), kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Little, dataProvider, NULL, YES, kCGRenderingIntentDefault);

    UIImage *image = [UIImage imageWithCGImage:coreImage];
    [self sendUIImagetoBackboardd:image];

}

- (void)sendUIImagetoBackboardd:(UIImage *)imageToSend {

    SInt32 req = CFMessagePortSendRequest(_messagingPort, 0, (CFDataRef)UIImagePNGRepresentation(imageToSend), 1000, 0, NULL, NULL);
    if (req != kCFMessagePortSuccess) {
        HBLogInfo(@"failed to send buffer to backboard: %s", strerror(errno));
    }
}

@end