#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface MGLScaleBar : UIView

// Sets the scale and redraws the scale bar
@property (nonatomic, assign) CLLocationDistance metersPerPoint;

/*
    The maximum width ratio of the scale bar relative to the map view's frame.
    This value is limited from 0.1 to 1.
    Default is 0.5(half of map view's width).
 */
@property (nonatomic, assign) CGFloat maximumWidthRatio;

@property (nonatomic, assign) CGPoint margins;

- (void)setNeedsRecalculateSize;

@end
