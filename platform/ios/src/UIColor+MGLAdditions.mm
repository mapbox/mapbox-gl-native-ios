#import "UIColor+MGLAdditions.h"

@implementation UIColor (MGLAdditions)

static inline unsigned ToByte(CGFloat f)
{
    f = MAX(0, MIN(f, 1)); // Clamp
    return (unsigned)round(f * 255);
}

- (mbgl::Color)mgl_color
{
    CGFloat r, g, b, a;
    [self getRed:&r green:&g blue:&b alpha:&a];
    // UIColor provides non-premultiplied color components, so we have to premultiply each
    // color component with the alpha value to transform it into a valid
    // mbgl::Color which expects premultiplied color components.
    return { static_cast<float>(r*a), static_cast<float>(g*a), static_cast<float>(b*a), static_cast<float>(a) };
}

- (NSArray *)mgl_rgbValueArray {
    CGFloat red, green, blue, alpha;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    if (alpha == 1.0) {
        return @[@(ToByte(red)), @(ToByte(green)), @(ToByte(blue))];
    }

    return @[@(ToByte(red)), @(ToByte(green)), @(ToByte(blue)), @(alpha)];
}

- (NSString *)mgl_rgbStringValue
{
    NSString *rgb = nil;
    NSArray *rgbValues = [self mgl_rgbValueArray];

    if ([rgbValues count] == 3) {
        rgb = [NSString stringWithFormat:@"rgb(%u, %u, %u)",
               [rgbValues[0] unsignedIntValue], [rgbValues[1] unsignedIntValue], [rgbValues[2] unsignedIntValue]];
    } else {
        rgb = [NSString stringWithFormat:@"rgba(%u, %u, %u, %g)",
        [rgbValues[0] unsignedIntValue], [rgbValues[1] unsignedIntValue], [rgbValues[2] unsignedIntValue], [rgbValues[3] floatValue]];
    }

    return rgb;
}

- (mbgl::style::PropertyValue<mbgl::Color>)mgl_colorPropertyValue
{
    mbgl::Color color = self.mgl_color;
    return {{ color.r, color.g, color.b, color.a }};
}

+ (UIColor *)mgl_colorWithColor:(mbgl::Color)color
{
    // If there is no alpha value, return original color values.
    if (color.a == 0.0f) {
        return [UIColor colorWithRed:color.r green:color.g blue:color.b alpha:color.a];
    }

    // mbgl::Color provides premultiplied color components, so we have to convert color
    // components to non-premultiplied values to return a valid UIColor object.
    float red = static_cast<float>((color.r / color.a));
    float green = static_cast<float>((color.g / color.a));
    float blue = static_cast<float>((color.b / color.a));

    return [UIColor colorWithRed:red green:green blue:blue alpha:color.a];
}

@end

@implementation NSExpression (MGLColorAdditions)

+ (NSExpression *)mgl_expressionForRGBComponents:(NSArray<NSExpression *> *)components {
    if (UIColor *color = [self mgl_colorWithRGBComponents:components]) {
        return [NSExpression expressionForConstantValue:color];
    }
    
    NSExpression *color = [NSExpression expressionForConstantValue:[UIColor class]];
    NSExpression *alpha = [NSExpression expressionForConstantValue:@1.0];
    return [NSExpression expressionForFunction:color
                                  selectorName:@"colorWithRed:green:blue:alpha:"
                                     arguments:[components arrayByAddingObject:alpha]];
}

+ (NSExpression *)mgl_expressionForRGBAComponents:(NSArray<NSExpression *> *)components {
    if (UIColor *color = [self mgl_colorWithRGBComponents:components]) {
        return [NSExpression expressionForConstantValue:color];
    }
    
    NSExpression *color = [NSExpression expressionForConstantValue:[UIColor class]];
    return [NSExpression expressionForFunction:color
                                  selectorName:@"colorWithRed:green:blue:alpha:"
                                     arguments:components];
}

+ (UIColor *)mgl_colorWithRGBComponents:(NSArray<NSExpression *> *)components {
    if (components.count < 3 || components.count > 4) {
        return nil;
    }
    
    for (NSExpression *component in components) {
        if (component.expressionType != NSConstantValueExpressionType) {
            return nil;
        }
        
        NSNumber *number = (NSNumber *)component.constantValue;
        if (![number isKindOfClass:[NSNumber class]]) {
            return nil;
        }
    }
    
    return [UIColor colorWithRed:[components[0].constantValue doubleValue] / 255.0
                           green:[components[1].constantValue doubleValue] / 255.0
                            blue:[components[2].constantValue doubleValue] / 255.0
                           alpha:components.count == 3 ? 1.0 : [components[3].constantValue doubleValue]];
}

@end
