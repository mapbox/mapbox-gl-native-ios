#import <Mapbox/Mapbox.h>
#import <XCTest/XCTest.h>

@interface MGLMapViewContentInsetTests : XCTestCase <MGLMapViewDelegate>

@property (nonatomic) MGLMapView *mapView;
@property (nonatomic) UIWindow *window;
@property (nonatomic) UIViewController *viewController;
@property (nonatomic) XCTestExpectation *styleLoadingExpectation;
@property (assign) CGRect screenBounds;

@end

@implementation MGLMapViewContentInsetTests

- (void)setUp {
    [super setUp];
    
    [MGLAccountManager setAccessToken:@"pk.feedcafedeadbeefbadebede"];
    NSURL *styleURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"one-liner" withExtension:@"json"];
    self.screenBounds = UIScreen.mainScreen.bounds;
    self.mapView = [[MGLMapView alloc] initWithFrame:self.screenBounds styleURL:styleURL];
    self.mapView.zoomLevel = 16;
    self.mapView.delegate = self;
    
    self.viewController = [[UIViewController alloc] init];
    self.viewController.view = [[UIView alloc] initWithFrame:self.screenBounds];
    [self.viewController.view addSubview:self.mapView];
    self.window = [[UIWindow alloc] initWithFrame:self.screenBounds];
    [self.window addSubview:self.viewController.view];
    [self.window makeKeyAndVisible];
    
    if (!self.mapView.style) {
        _styleLoadingExpectation = [self expectationWithDescription:@"Map view should finish loading style."];
        [self waitForExpectationsWithTimeout:10 handler:nil];
    }
}

- (void)mapView:(MGLMapView *)mapView didFinishLoadingStyle:(MGLStyle *)style {
    XCTAssertNotNil(mapView.style);
    XCTAssertEqual(mapView.style, style);
    
    [_styleLoadingExpectation fulfill];
}

- (void)tearDown {
    self.mapView = nil;
    [MGLAccountManager setAccessToken:nil];
    [super tearDown];
}

- (void)testContentInsetCenter {
    CLLocationCoordinate2D center = CLLocationCoordinate2DMake(1.0, 5.0);
    [self.mapView setCenterCoordinate:center zoomLevel:10 animated:NO];
    self.mapView.contentInset = UIEdgeInsetsZero;
    
    XCTAssertEqualWithAccuracy(self.mapView.centerCoordinate.latitude, center.latitude, 0.01);
    XCTAssertEqualWithAccuracy(self.mapView.centerCoordinate.longitude, center.longitude, 0.01);
    
    CGPoint centerPoint = [self.mapView convertCoordinate:center toPointToView:self.mapView];

    XCTAssertEqualWithAccuracy(centerPoint.x, self.screenBounds.size.width/2, 0.01);
    XCTAssertEqualWithAccuracy(centerPoint.y, self.screenBounds.size.height/2, 0.01);
    
    // shifting contentInset should keep the same centerCoordinate but shift the screen
    // center point accordingly
    UIEdgeInsets contentInset = UIEdgeInsetsMake(50.0, 10.0, 10.0, 30.0);
    self.mapView.contentInset = contentInset;
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(self.mapView.contentInset, contentInset));
    XCTAssertEqualWithAccuracy(self.mapView.centerCoordinate.latitude, center.latitude, 0.01);
    XCTAssertEqualWithAccuracy(self.mapView.centerCoordinate.longitude, center.longitude, 0.01);
    CGPoint shiftedPoint = [self.mapView convertCoordinate:center toPointToView:self.mapView];
    CGPoint expectedShiftedPoint = CGPointMake((self.screenBounds.size.width/2) + ((contentInset.left - contentInset.right) / 2 ),
                                               (self.screenBounds.size.height/2) + ((contentInset.top - contentInset.bottom) / 2));
    XCTAssertEqualWithAccuracy(shiftedPoint.x, expectedShiftedPoint.x, 0.01);
    XCTAssertEqualWithAccuracy(shiftedPoint.y, expectedShiftedPoint.y, 0.01);
    
  
}

- (void)testContentInsetOrnaments {
    UIEdgeInsets margin = UIEdgeInsetsMake(8, 8, 8, 8);
    
    if (@available(iOS 11.0, *)) {
        UIEdgeInsets safeInsets = self.mapView.safeAreaInsets;
        margin.top += safeInsets.top;
        margin.bottom += safeInsets.bottom;
        margin.left += safeInsets.left;
        margin.right += safeInsets.right;
    }

    self.mapView.contentInset = UIEdgeInsetsZero;
    UIView *scaleBar = self.mapView.scaleBar;
    CGPoint expectedScaleBarOrigin = CGPointMake(margin.left, margin.top);
    XCTAssertTrue(CGPointEqualToPoint(scaleBar.frame.origin, expectedScaleBarOrigin));
    
    UIView *compassView = self.mapView.compassView;
    CGFloat x = self.screenBounds.size.width - compassView.bounds.size.width - margin.right;
    CGPoint expectedCompassOrigin = CGPointMake(x, margin.top);
    XCTAssertTrue(CGPointEqualToPoint(compassView.frame.origin, expectedCompassOrigin));
                  
    UIView *logoView = self.mapView.logoView;
    CGFloat y = self.screenBounds.size.height - logoView.bounds.size.height - margin.bottom;
    CGPoint expectedLogoOrigin = CGPointMake(margin.left, y);
    XCTAssertTrue(CGPointEqualToPoint(logoView.frame.origin, expectedLogoOrigin));
    
    UIView *attributionView = self.mapView.attributionButton;
    x = self.screenBounds.size.width - attributionView.bounds.size.width - margin.right;
    y = self.screenBounds.size.height - attributionView.bounds.size.height - margin.bottom;
    CGPoint expectedAttributionOrigin = CGPointMake(x, y);
    XCTAssertTrue(CGPointEqualToPoint(attributionView.frame.origin, expectedAttributionOrigin));
    
    UIEdgeInsets insets = UIEdgeInsetsMake(15, 10, 20, 5);
    self.viewController.automaticallyAdjustsScrollViewInsets = NO;
    self.mapView.contentInset = insets;

    [self.mapView setNeedsLayout];
    [self.mapView layoutIfNeeded];

    expectedScaleBarOrigin = CGPointMake(insets.left + self.mapView.scaleBarMargins.x, insets.top  + self.mapView.scaleBarMargins.y);
    XCTAssertTrue(CGPointEqualToPoint(scaleBar.frame.origin, expectedScaleBarOrigin));

    x = self.screenBounds.size.width - compassView.bounds.size.width - insets.right - self.mapView.compassViewMargins.x;
    expectedCompassOrigin = CGPointMake(x, insets.top + self.mapView.compassViewMargins.y);
    XCTAssertTrue(CGPointEqualToPoint(compassView.frame.origin, expectedCompassOrigin));

    y = self.screenBounds.size.height - logoView.bounds.size.height - insets.bottom - self.mapView.logoViewMargins.y;
    expectedLogoOrigin = CGPointMake(insets.left + self.mapView.logoViewMargins.x, y);
    XCTAssertTrue(CGPointEqualToPoint(logoView.frame.origin, expectedLogoOrigin));

    x = self.screenBounds.size.width - attributionView.bounds.size.width - insets.right - self.mapView.attributionButtonMargins.x;
    y = self.screenBounds.size.height - attributionView.bounds.size.height - insets.bottom - self.mapView.attributionButtonMargins.y;
    expectedAttributionOrigin = CGPointMake(x, y);
    XCTAssertTrue(CGPointEqualToPoint(attributionView.frame.origin, expectedAttributionOrigin));

    // tests that passing negative values result in a 0 inset value
    insets = UIEdgeInsetsMake(-100, -100, -100, -100);
    self.mapView.contentInset = insets;

    [self.mapView setNeedsLayout];
    [self.mapView layoutIfNeeded];
    
    margin = UIEdgeInsetsMake(8, 8, 8, 8);

    expectedScaleBarOrigin = CGPointMake(margin.left, margin.top);
    XCTAssertTrue(CGPointEqualToPoint(scaleBar.frame.origin, expectedScaleBarOrigin));

    x = self.screenBounds.size.width - compassView.bounds.size.width - margin.right;
    expectedCompassOrigin = CGPointMake(x, margin.top);
    XCTAssertTrue(CGPointEqualToPoint(compassView.frame.origin, expectedCompassOrigin));

    y = self.screenBounds.size.height - logoView.bounds.size.height - margin.bottom;
    expectedLogoOrigin = CGPointMake(margin.left, y);
    XCTAssertTrue(CGPointEqualToPoint(logoView.frame.origin, expectedLogoOrigin));

    x = self.screenBounds.size.width - attributionView.bounds.size.width - margin.right;
    y = self.screenBounds.size.height - attributionView.bounds.size.height - margin.bottom;
    expectedAttributionOrigin = CGPointMake(x, y);
    XCTAssertTrue(CGPointEqualToPoint(attributionView.frame.origin, expectedAttributionOrigin));

    self.mapView.automaticallyAdjustsContentInset = YES;
    insets = UIEdgeInsetsMake(100, 100, 100, 100);
    self.mapView.contentInset = insets;
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(self.mapView.contentInset, insets));

    [self.mapView setNeedsLayout];
    [self.mapView layoutIfNeeded];
    
    if (@available(iOS 11.0, *)) {
        UIEdgeInsets safeInsets = self.mapView.safeAreaInsets;
        margin.top += safeInsets.top;
        margin.bottom += safeInsets.bottom;
        margin.left += safeInsets.left;
        margin.right += safeInsets.right;
    }

    // when automaticallyAdjustsContentInset = YES the content insets should be overwriten
    XCTAssertFalse(UIEdgeInsetsEqualToEdgeInsets(self.mapView.contentInset, insets));

    expectedScaleBarOrigin = CGPointMake(margin.left, margin.top);
    XCTAssertTrue(CGPointEqualToPoint(scaleBar.frame.origin, expectedScaleBarOrigin));

    x = self.screenBounds.size.width - compassView.bounds.size.width - margin.right;
    expectedCompassOrigin = CGPointMake(x, margin.top);
    XCTAssertTrue(CGPointEqualToPoint(compassView.frame.origin, expectedCompassOrigin));

    y = self.screenBounds.size.height - logoView.bounds.size.height - margin.bottom;
    expectedLogoOrigin = CGPointMake(margin.left, y);
    XCTAssertTrue(CGPointEqualToPoint(logoView.frame.origin, expectedLogoOrigin));

    x = self.screenBounds.size.width - attributionView.bounds.size.width - margin.right;
    y = self.screenBounds.size.height - attributionView.bounds.size.height - margin.bottom;
    expectedAttributionOrigin = CGPointMake(x, y);
    XCTAssertTrue(CGPointEqualToPoint(attributionView.frame.origin, expectedAttributionOrigin));
    
}

@end
