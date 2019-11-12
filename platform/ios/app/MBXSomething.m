//@import Mapbox;
//@import MapboxMobileEvents;
#import <MapboxMobileEvents/MapboxMobileEvents.h>
#import "MBXSomething.h"

@implementation MBXSomething
- (instancetype)init {
    NSLog(@"thing = %@", [MMEEventsManager sharedManager]);
    return nil;
}
@end
