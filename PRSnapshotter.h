#import "prettyrespring.h"

@interface PRSnapshotter : NSObject

@property (nonatomic) IOSurfaceRef screenSurface;
@property (nonatomic) CFMessagePortRef messagingPort;

- (void)captureScreen;
- (void)sendUIImagetoBackboardd:(UIImage *)imageToSend;

@end