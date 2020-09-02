#import <UIKit/UIKit.h>

#import "MGLFoundation.h"

NS_ASSUME_NONNULL_BEGIN

/**
 A class containing information about the default User Location annotation view style.
 */
MGL_EXPORT
@interface MGLUserLocationAnnotationViewStyle : NSObject

/**
 The puck's view fill color.
 */
@property (nonatomic) UIColor *puckFillColor;
/**
 The puck's view shadow color.
 */
@property (nonatomic) UIColor *puckShadowColor;
/**
 The puck's view shadow opacity.
 Set any value between 0.0 and 1.0.
 The default value of this property is equal to `0.25`
 */
@property (nonatomic, assign) CGFloat puckShadowOpacity;
/**
 The puck's arrow fill color.
 */
@property (nonatomic) UIColor *puckArrowFillColor;
/**
 The puck's halo fill color.
 */
@property (nonatomic) UIColor *haloFillColor;
/**
 The approximate's view halo fill color.
 */
@property (nonatomic) UIColor *approximateHaloFillColor;
/**
 The approximate's view halo border color.
 */
@property (nonatomic) UIColor *approximateHaloBorderColor;
/**
 The approximate's view halo border width.
 The default value of this property is equal to `2.0`
 */
@property (nonatomic, assign) CGFloat approximateHaloBorderWidth;
/**
 The approximate's view halo opacity.
 Set any value between 0.0 and 1.0
 The default value of this property is equal to `0.15`
 */
@property (nonatomic, assign) CGFloat approximateHaloOpacity;

@end

NS_ASSUME_NONNULL_END
