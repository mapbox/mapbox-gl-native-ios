#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


/**
A  view that displays a scale depending of the current zoom level and unit of length.
*/
MGL_EXPORT
@interface MGLScaleBar : UIView

/**
The primary color of the scale bar, which will be used to draw odd index blocks.
*/
@property (nonatomic) UIColor *primaryColor;

/**
The secondary color of the scale bar, which will be used to draw even index blocks.
*/
@property (nonatomic) UIColor *secondaryColor;

/**
The label color of the scale bar,  will be used to draw distance labels.
*/
@property (nonatomic) UIColor *labelColor;

@end

NS_ASSUME_NONNULL_END
