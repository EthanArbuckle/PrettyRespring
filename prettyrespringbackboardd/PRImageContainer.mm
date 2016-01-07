#import "PRImageContainer.h"

@implementation PRImageContainer

+ (id)sharedInstance {
    static dispatch_once_t p = 0;
    __strong static id _sharedObject = nil;

    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });

    return _sharedObject;
}

- (UIImage *)getSpringboardImage {
    return [[UIImage alloc] initWithData:_storedData];
}

- (void)setSpringboardImage:(NSData *)data {
    _storedData = [[NSData alloc] initWithData:data];
}

@end