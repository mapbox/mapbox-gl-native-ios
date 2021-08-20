#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSOrthography (NSOrthography_MGLAdditions)

/**
 Returns a four-letter ISO 15924 code representing the name of the dominant
 script for a given language, or nil if language is nil.

 On iOS 11 or newer, this method wraps
 `+[NSOrthography defaultOrthographyForLanguage:]` and supports any language.
 On iOS 10 and older, this method only returns values for Mapbox
 Streets-supported languages.

 @param language The ISO-639 code representing a language.
 */
+ (nullable NSString *)mgl_dominantScriptForMapboxStreetsLanguage:(nullable NSString *)language;

@end

NS_ASSUME_NONNULL_END
