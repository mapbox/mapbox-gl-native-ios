
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#import "MGLScaleBar.h"

NS_ASSUME_NONNULL_BEGIN

@interface MGLScaleBar (Private)

// Sets the scale and redraws the scale bar
@property (nonatomic, assign) CLLocationDistance metersPerPoint;

@end

NS_ASSUME_NONNULL_END
