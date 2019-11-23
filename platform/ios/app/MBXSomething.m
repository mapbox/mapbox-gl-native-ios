@import Mapbox;
@import MapboxMobileEvents;
#import "MBXSomething.h"

@implementation MBXSomething
- (instancetype)init {
    NSLog(@"thing = %@", [MMEEventsManager sharedManager]);
    return nil;
}
@end
