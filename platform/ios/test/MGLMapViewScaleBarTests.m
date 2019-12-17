#import <Mapbox/Mapbox.h>
#import <XCTest/XCTest.h>

@interface MGLMapViewScaleBarTests : XCTestCase

@property (nonatomic) MGLMapView *mapView;

@end

@implementation MGLMapViewScaleBarTests

- (void)setUp {
    [super setUp];

    [MGLAccountManager setAccessToken:@"pk.feedcafedeadbeefbadebede"];
    NSURL *styleURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"one-liner" withExtension:@"json"];
    self.mapView = [[MGLMapView alloc] initWithFrame:UIScreen.mainScreen.bounds styleURL:styleURL];
}

- (void)tearDown {
    self.mapView = nil;
    [MGLAccountManager setAccessToken:nil];

    [super tearDown];
}

- (void)testShowsScale {
    UIView *scaleBar = self.mapView.scaleBar;

    // Scale bar should not be enabled by default.
    XCTAssertFalse(self.mapView.showsScale);
    XCTAssertTrue(scaleBar.hidden);

    self.mapView.showsScale = YES;

    XCTAssertFalse(scaleBar.hidden);

    // Scale bar should not be visible at default zoom (~z0), but it should be ready.
    // Size is not a measure of readiness here though.
    XCTAssertTrue(CGSizeEqualToSize(scaleBar.intrinsicContentSize, CGSizeZero));
    XCTAssertEqual(scaleBar.alpha, 0);

    self.mapView.zoomLevel = 15;
    [self.mapView layoutIfNeeded];
    XCTAssertGreaterThan(scaleBar.alpha, 0);
    XCTAssertFalse(CGSizeEqualToSize(scaleBar.intrinsicContentSize, CGSizeZero));
}

- (void)testDirectlySettingScaleBarViewHiddenProperty {
    UIView *scaleBar = self.mapView.scaleBar;

    scaleBar.hidden = NO;
    XCTAssertFalse(scaleBar.hidden);

    // Directly setting `.hidden` after the map has finished initializing will not update the scale bar.
    XCTAssertTrue(CGSizeEqualToSize(scaleBar.intrinsicContentSize, CGSizeZero));

    // ... but triggering any camera event will update it.
    self.mapView.zoomLevel = 1;
    [self.mapView layoutIfNeeded];

    XCTAssertTrue(CGSizeEqualToSize(scaleBar.intrinsicContentSize, CGSizeZero));
    XCTAssertEqual(scaleBar.alpha, 0);

    self.mapView.zoomLevel = 15;
    [self.mapView layoutIfNeeded];

    XCTAssertGreaterThan(scaleBar.alpha, 0);
    XCTAssertFalse(CGSizeEqualToSize(scaleBar.intrinsicContentSize, CGSizeZero));
}

- (void)testScaleBarSizeChanged {
    self.mapView.scaleBarMaximumWidthRatio = 0.5;
    UIView *scaleBar = self.mapView.scaleBar;
    scaleBar.hidden = NO;
    
    self.mapView.zoomLevel = 15;
    [self.mapView layoutIfNeeded];
    
    XCTAssertLessThanOrEqual(scaleBar.intrinsicContentSize.width, self.mapView.frame.size.width/2);
    
    self.mapView.zoomLevel = 10;
    [self.mapView layoutIfNeeded];
    XCTAssertLessThanOrEqual(scaleBar.intrinsicContentSize.width, self.mapView.frame.size.width/2);
    
    CGRect frame = self.mapView.frame;
    frame.size = CGSizeMake(frame.size.width/2, frame.size.height);
    self.mapView.frame = frame;
    [self.mapView layoutIfNeeded];
    
    // The bar maximum bar width can only limit the bar's total width.
    // Since we should include some space for last label width, the maximum last label width is 30.
    // However, the last label cannot be out of bounds by constraints.
    CGFloat scaleBarLabelWidthHint = 30.0f;
    
    XCTAssertLessThanOrEqual(scaleBar.intrinsicContentSize.width, self.mapView.frame.size.width/2 + scaleBarLabelWidthHint);
}

@end
