#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface MGLScaleBar : UIView

// Sets the scale and redraws the scale bar
@property (nonatomic, assign) CLLocationDistance metersPerPoint;

// Sets whether the scale on the right side of screen
@property (nonatomic, assign) BOOL isOnScreenRight;

@end
