#import "../prettyrespring.h"

@interface PRImageContainer : NSObject

@property (nonatomic, retain) NSData *storedData;
@property (nonatomic) BOOL recoveringFromPrettyRespring;
+ (id)sharedInstance;
- (UIImage *)getSpringboardImage;
- (void)setSpringboardImage:(NSData *)data;

@end
