#import <Mapbox/Mapbox.h>
#import <XCTest/XCTest.h>
#import "MGLRendererConfiguration_Private.h"

static NSString * const MGLRendererConfigurationTests_collisionBehaviorKey = @"MGLCollisionBehaviorPre4_0";

@interface MGLRendererConfigurationTests : XCTestCase
@end

@implementation MGLRendererConfigurationTests
- (void)setUp {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MGLRendererConfigurationTests_collisionBehaviorKey];
}

- (void)tearDown {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:MGLRendererConfigurationTests_collisionBehaviorKey];
}

// Emulate what would happen with an Info.plist.
- (void)testSettingMGLCollisionBehaviorPre40
{
    MGLRendererConfiguration *config = [[MGLRendererConfiguration alloc] init];
    XCTAssertFalse([config perSourceCollisionsWithInfoDictionaryObject:nil]);
    XCTAssertFalse([config perSourceCollisionsWithInfoDictionaryObject:@(NO)]);
    XCTAssertTrue([config perSourceCollisionsWithInfoDictionaryObject:@(YES)]);
    XCTAssertFalse([config perSourceCollisionsWithInfoDictionaryObject:@"NO"]);
    XCTAssertTrue([config perSourceCollisionsWithInfoDictionaryObject:@"YES"]);
}

- (void)testSettingMGLCollisionBehaviorPre40InNSUserDefaults {
    {
        XCTAssertNil([[NSUserDefaults standardUserDefaults] objectForKey:MGLRendererConfigurationTests_collisionBehaviorKey]);
        MGLRendererConfiguration *config = [MGLRendererConfiguration currentConfiguration];
        XCTAssertFalse(config.perSourceCollisions);
        XCTAssertFalse([config perSourceCollisionsWithInfoDictionaryObject:nil]);
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:@(NO) forKey:MGLRendererConfigurationTests_collisionBehaviorKey];
    {
        XCTAssertNotNil([[NSUserDefaults standardUserDefaults] objectForKey:MGLRendererConfigurationTests_collisionBehaviorKey]);
        MGLRendererConfiguration *config = [MGLRendererConfiguration currentConfiguration];
        XCTAssertFalse(config.perSourceCollisions);
        XCTAssertFalse([config perSourceCollisionsWithInfoDictionaryObject:@(NO)]);
        XCTAssertFalse([config perSourceCollisionsWithInfoDictionaryObject:@(YES)]);
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:MGLRendererConfigurationTests_collisionBehaviorKey];
    {
        XCTAssertNotNil([[NSUserDefaults standardUserDefaults] objectForKey:MGLRendererConfigurationTests_collisionBehaviorKey]);
        MGLRendererConfiguration *config = [MGLRendererConfiguration currentConfiguration];
        XCTAssert(config.perSourceCollisions);
        XCTAssertTrue([config perSourceCollisionsWithInfoDictionaryObject:@(NO)]);
        XCTAssertTrue([config perSourceCollisionsWithInfoDictionaryObject:@(YES)]);
    }
}

- (void)testOverridingMGLCollisionBehaviorPre40 {
    // Dictionary = NO, NSUserDefaults = YES
    {
        [[NSUserDefaults standardUserDefaults] setObject:@(YES) forKey:MGLRendererConfigurationTests_collisionBehaviorKey];
        MGLRendererConfiguration *config = [[MGLRendererConfiguration alloc] init];
        XCTAssert([config perSourceCollisionsWithInfoDictionaryObject:@(NO)]);
    }
    // Dictionary = YES, NSUserDefaults = NO
    {
        [[NSUserDefaults standardUserDefaults] setObject:@(NO) forKey:MGLRendererConfigurationTests_collisionBehaviorKey];
        MGLRendererConfiguration *config = [[MGLRendererConfiguration alloc] init];
        XCTAssertFalse([config perSourceCollisionsWithInfoDictionaryObject:@(YES)]);
    }
}

- (void)testDefaultLocalFontFamilyName {
    
    MGLRendererConfiguration *config = [[MGLRendererConfiguration alloc] init];
    NSString *localFontFamilyName = config.localFontFamilyName;
    
    NSString *systemFontFamilyName;
#if TARGET_OS_IPHONE
    systemFontFamilyName = [UIFont systemFontOfSize:0 weight:UIFontWeightRegular].familyName;
#else
    systemFontFamilyName = [NSFont systemFontOfSize:0 weight:NSFontWeightRegular].familyName;
#endif
    
    XCTAssertEqualObjects(localFontFamilyName, systemFontFamilyName, @"Default local font family name should match default system font");
}

- (void)testSettingMGLIdeographicFontFamilyNameWithPlistValue {
    
    MGLRendererConfiguration *config = [[MGLRendererConfiguration alloc] init];
    
    // `MGLIdeographicFontFamilyName` set to bool value `YES`
    {
        NSString *localFontFamilyName = [config localFontFamilyNameWithInfoDictionaryObject:@(YES)];
        
        NSString *systemFontFamilyName;
#if TARGET_OS_IPHONE
        systemFontFamilyName = [UIFont systemFontOfSize:0 weight:UIFontWeightRegular].familyName;
#else
        systemFontFamilyName = [NSFont systemFontOfSize:0 weight:NSFontWeightRegular].familyName;
#endif
        XCTAssertEqualObjects(localFontFamilyName, systemFontFamilyName, @"Local font family name should match default system font name when setting `YES`");
    }
    
    // `MGLIdeographicFontFamilyName` set to bool value `NO`
    {
        NSString *localFontFamilyName = [config localFontFamilyNameWithInfoDictionaryObject:@(NO)];
        XCTAssertNil(localFontFamilyName, @"Client rendering font should use remote font when setting `NO`");
    }
    
    // `MGLIdeographicFontFamilyName` set to a valid font string value
    {
        NSString *localFontFamilyName = [config localFontFamilyNameWithInfoDictionaryObject:@"PingFang TC"];
        XCTAssertEqualObjects(localFontFamilyName, @"PingFang TC", @"Local font family name should match a custom valid font name");
    }
    
    // `MGLIdeographicFontFamilyName` set to an invalid font string value
    {
        NSString *localFontFamilyName = [config localFontFamilyNameWithInfoDictionaryObject:@"test font"];
        
        NSString *systemFontFamilyName;
#if TARGET_OS_IPHONE
        systemFontFamilyName = [UIFont systemFontOfSize:0 weight:UIFontWeightRegular].familyName;
#else
        systemFontFamilyName = [NSFont systemFontOfSize:0 weight:NSFontWeightRegular].familyName;
#endif
        XCTAssertNotEqualObjects(localFontFamilyName, systemFontFamilyName, @"Local font family name should not be validated by MGLRenderConfiguration");
    }
    
    // `MGLIdeographicFontFamilyName` set to a valid font family names array value
    {
        NSString *localFontFamilyName = [config localFontFamilyNameWithInfoDictionaryObject:@[@"test font 1", @"PingFang TC", @"test font 2"]];
        XCTAssertEqualObjects(localFontFamilyName, @"test font 1\nPingFang TC\ntest font 2");
    }
    
    // `MGLIdeographicFontFamilyName` set to an invalid font family names array value
    {
        NSString *localFontFamilyName = [config localFontFamilyNameWithInfoDictionaryObject:@[@"test font 1", @"test font 2", @"test font 3"]];
        
        NSString *systemFontFamilyName;
#if TARGET_OS_IPHONE
        systemFontFamilyName = [UIFont systemFontOfSize:0 weight:UIFontWeightRegular].familyName;
#else
        systemFontFamilyName = [NSFont systemFontOfSize:0 weight:NSFontWeightRegular].familyName;
#endif
        XCTAssertEqualObjects(localFontFamilyName, @"test font 1\ntest font 2\ntest font 3", @"Local font family name should not be validated by MGLRendererConfiguration");
    }
    
    // `MGLIdeographicFontFamilyName` set to an invalid value type: NSDictionary, NSNumber, NSData, etc.
    {
        NSString *localFontFamilyName = [config localFontFamilyNameWithInfoDictionaryObject:[@"test font 1" dataUsingEncoding:NSUTF8StringEncoding]];
        
        NSString *systemFontFamilyName;
#if TARGET_OS_IPHONE
        systemFontFamilyName = [UIFont systemFontOfSize:0 weight:UIFontWeightRegular].familyName;
#else
        systemFontFamilyName = [NSFont systemFontOfSize:0 weight:NSFontWeightRegular].familyName;
#endif
        XCTAssertEqualObjects(localFontFamilyName, systemFontFamilyName, @"Local font family name should match default system font name when setting an invalid value type");
    }
}

- (void)testMGLGlyphsRasterizationModeWithPlistValue {
    MGLRendererConfiguration *config = [[MGLRendererConfiguration alloc] init];

    // `MGLGlyphsRasterizationMode` set to nil or not set.
    {
        MGLGlyphsRasterizationMode mode = [config glyphsRasterizationModeWithInfoDictionaryObject:nil];

        XCTAssertEqual(mode, MGLGlyphsRasterizationModeNone, @"Glyphs rasterization mode should be `MGLGlyphsRasterizationModeNone` when it setting to nil or not set");
    }

    // `MGLGlyphsRasterizationMode` set to invalid value.
    {
        MGLGlyphsRasterizationMode mode = [config glyphsRasterizationModeWithInfoDictionaryObject:@"invalide option value"];

        XCTAssertEqual(mode, MGLGlyphsRasterizationModeNone, @"Glyphs rasterization mode should be `MGLGlyphsRasterizationModeNone` when it setting to invalid value.");
    }

    // `MGLGlyphsRasterizationMode` set to "MGLNoGlyphsRasterizedLocally".
    {
        MGLGlyphsRasterizationMode mode = [config glyphsRasterizationModeWithInfoDictionaryObject:@"MGLNoGlyphsRasterizedLocally"];

        XCTAssertEqual(mode, MGLGlyphsRasterizationModeNoGlyphsRasterizedLocally, @"Glyphs rasterization mode should be `MGLGlyphsRasterizationModeNoGlyphsRasterizedLocally`.");
    }

    // `MGLGlyphsRasterizationMode` set to "MGLGlyphsRasterizationModeIdeographsRasterizedLocally".
    {
        MGLGlyphsRasterizationMode mode = [config glyphsRasterizationModeWithInfoDictionaryObject:@"MGLIdeographsRasterizedLocally"];

        XCTAssertEqual(mode, MGLGlyphsRasterizationModeIdeographsRasterizedLocally, @"Glyphs rasterization mode should be `MGLGlyphsRasterizationModeIdeographsRasterizedLocally`.");
    }

    // `MGLGlyphsRasterizationMode` set to "MGLAllGlyphsRasterizedLocally".
    {
        MGLGlyphsRasterizationMode mode = [config glyphsRasterizationModeWithInfoDictionaryObject:@"MGLAllGlyphsRasterizedLocally"];

        XCTAssertEqual(mode, MGLGlyphsRasterizationModeAllGlyphsRasterizedLocally, @"Glyphs rasterization mode should be `MGLAllGlyphsRasterizedLocally`.");
    }
}

- (void)testGlyphsRasterizationOptions {
    MGLRendererConfiguration *config = [[MGLRendererConfiguration alloc] init];

    // `MGLIdeographicFontFamilyName` unset, MGLGlyphsRasterizationMode set to AllGlyphsRasterizedLocally.
    {
        mbgl::GlyphsRasterizationOptions options = [config glyphsRasterizationOptionsWithLocalFontFamilyName:nil rasterizationMode:MGLGlyphsRasterizationModeAllGlyphsRasterizedLocally];

        XCTAssertEqual(options.fontFamily, mbgl::nullopt, @"Font family name should be `nullptr`");
        XCTAssertEqual(options.rasterizationMode, mbgl::GlyphsRasterizationMode::NoGlyphsRasterizedLocally, @"Glyphs rasterization mode should be `NoGlyphsRasterizedLocally`");
    }
    
    // `MGLIdeographicFontFamilyName` unset, MGLGlyphsRasterizationMode set to NoGlyphsRasterizedLocally.
    {
        mbgl::GlyphsRasterizationOptions options = [config glyphsRasterizationOptionsWithLocalFontFamilyName:nil rasterizationMode:MGLGlyphsRasterizationModeNoGlyphsRasterizedLocally];

        XCTAssertEqual(options.fontFamily, mbgl::nullopt, @"Font family name should be `nullptr`");
        XCTAssertEqual(options.rasterizationMode, mbgl::GlyphsRasterizationMode::NoGlyphsRasterizedLocally, @"Glyphs rasterization mode should be `NoGlyphsRasterizedLocally`");
    }
    
    // `MGLIdeographicFontFamilyName` set to "Ping Fang", MGLGlyphsRasterizationMode set to IdeographsRasterizedLocally.
    {
        mbgl::GlyphsRasterizationOptions options = [config glyphsRasterizationOptionsWithLocalFontFamilyName:@"Ping Fang" rasterizationMode:MGLGlyphsRasterizationModeIdeographsRasterizedLocally];

        XCTAssertEqual(options.fontFamily, std::string(@"Ping Fang".UTF8String), @"Font family name should be `Ping Fang`");
        XCTAssertEqual(options.rasterizationMode, mbgl::GlyphsRasterizationMode::IdeographsRasterizedLocally, @"Glyphs rasterization mode should be `IdeographsRasterizedLocally`");
    }
    
    // `MGLIdeographicFontFamilyName` set to "Ping Fang", MGLGlyphsRasterizationMode set to NoGlyphsRasterizedLocally.
    {
        mbgl::GlyphsRasterizationOptions options = [config glyphsRasterizationOptionsWithLocalFontFamilyName:@"Ping Fang" rasterizationMode:MGLGlyphsRasterizationModeNoGlyphsRasterizedLocally];

        XCTAssertEqual(options.fontFamily, std::string(@"Ping Fang".UTF8String), @"Font family name should be `Ping Fang`");
        XCTAssertEqual(options.rasterizationMode, mbgl::GlyphsRasterizationMode::NoGlyphsRasterizedLocally, @"Glyphs rasterization mode should be `NoGlyphsRasterizedLocally`");
    }
    
    // `MGLIdeographicFontFamilyName` set to "Ping Fang", MGLGlyphsRasterizationMode set to AllGlyphsRasterizedLocally.
    {
        mbgl::GlyphsRasterizationOptions options = [config glyphsRasterizationOptionsWithLocalFontFamilyName:@"Ping Fang" rasterizationMode:MGLGlyphsRasterizationModeAllGlyphsRasterizedLocally];

        XCTAssertEqual(options.fontFamily, std::string(@"Ping Fang".UTF8String), @"Font family name should be `Ping Fang`");
        XCTAssertEqual(options.rasterizationMode, mbgl::GlyphsRasterizationMode::AllGlyphsRasterizedLocally, @"Glyphs rasterization mode should be `AllGlyphsRasterizedLocally`");
    }
    
    // `MGLIdeographicFontFamilyName` set to "Ping Fang", MGLGlyphsRasterizationMode unset.
    {
        mbgl::GlyphsRasterizationOptions options = [config glyphsRasterizationOptionsWithLocalFontFamilyName:@"Ping Fang" rasterizationMode:MGLGlyphsRasterizationModeNone];

        XCTAssertEqual(options.fontFamily, std::string(@"Ping Fang".UTF8String), @"Font family name should be `Ping Fang`");
        XCTAssertEqual(options.rasterizationMode, mbgl::GlyphsRasterizationMode::NoGlyphsRasterizedLocally, @"Glyphs rasterization mode should be `NoGlyphsRasterizedLocally`");
    }
}

@end
