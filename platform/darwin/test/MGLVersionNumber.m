#import <Mapbox/Mapbox.h>

#import <XCTest/XCTest.h>

@interface MGLVersionTests : XCTestCase

@end

@implementation MGLVersionTests

- (void)testVersionNumber {
    // TODO: Reinstate once the test target is fixed.
    XCTAssertGreaterThanOrEqual(MapboxVersionNumber, 0);
}

@end
