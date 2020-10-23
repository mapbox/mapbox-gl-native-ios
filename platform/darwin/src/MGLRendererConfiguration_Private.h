#import "MGLRendererConfiguration.h"
#include <mbgl/map/glyphs_rasterization_options.hpp>


NS_ASSUME_NONNULL_BEGIN

@interface MGLRendererConfiguration (Private)

- (mbgl::GlyphsRasterizationOptions)glyphsRasterizationOptions;

- (mbgl::GlyphsRasterizationOptions)glyphsRasterizationOptionsWithLocalFontFamilyName:(nullable NSString *)fontFamilyName
                                                                    rasterizationMode:(MGLGlyphsRasterizationMode)rasterizationMode;

@end

NS_ASSUME_NONNULL_END
