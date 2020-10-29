#import <UIKit/UIKit.h>

#import "MGLCompassButton.h"

@class MGLMapView;

NS_ASSUME_NONNULL_BEGIN

@interface MGLCompassButton (Private)

+ (instancetype)compassButtonWithMapView:(MGLMapView *)mapView;

@property (nonatomic, weak) MGLMapView *mapView;
@property (nonatomic) CALayer *imageLayer;

- (void)updateCompass;

@end

NS_ASSUME_NONNULL_END
