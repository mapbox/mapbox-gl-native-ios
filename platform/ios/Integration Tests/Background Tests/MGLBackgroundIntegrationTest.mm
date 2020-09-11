#import "MGLMapViewIntegrationTest.h"
#import "MGLMockApplication.h"
#import "MGLMapView_Private.h"

@interface MGLMapView (BackgroundTests)
@property (nonatomic, weak) id<MGLApplication> application;

@property (nonatomic, getter=isDormant) BOOL dormant;
@property (nonatomic, readonly, getter=isDisplayLinkActive) BOOL displayLinkActive;
@property (nonatomic) CADisplayLink *displayLink;
- (void)updateFromDisplayLink:(CADisplayLink *)displayLink;
@end

@protocol MGLApplication;

typedef void (^MGLNotificationBlock)(NSNotification*);

#pragma mark - MGLBackgroundIntegrationTestMapView

@interface MGLBackgroundIntegrationTestMapView : MGLMapView
@property (nonatomic, copy) dispatch_block_t displayLinkDidUpdate;
@end

@implementation MGLBackgroundIntegrationTestMapView
- (void)updateFromDisplayLink:(CADisplayLink *)displayLink {
    [super updateFromDisplayLink:displayLink];
    
    if (self.displayLinkDidUpdate) {
        self.displayLinkDidUpdate();
    }
}
@end

#pragma mark - MGLBackgroundIntegrationTest

@interface MGLBackgroundIntegrationTest : MGLMapViewIntegrationTest

@property (nonatomic) MGLMockApplication *mockApplication;
@property (nonatomic, copy) MGLNotificationBlock willResignActive;
@property (nonatomic, copy) MGLNotificationBlock didEnterBackground;
@property (nonatomic, copy) MGLNotificationBlock willEnterForeground;
@property (nonatomic, copy) MGLNotificationBlock didBecomeActive;

@property (nonatomic, copy) dispatch_block_t displayLinkDidUpdate;
@end

@implementation MGLBackgroundIntegrationTest

- (void)setUp {
    self.mockApplication = [[MGLMockApplication alloc] init];

    // Register notifications *BEFORE* MGLMapView does.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:self.mockApplication];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:self.mockApplication];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:self.mockApplication];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:self.mockApplication];

    [super setUp];

    // Now override
    self.mapView.application = self.mockApplication;
}

- (void)tearDown {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.willResignActive = NULL;
    self.didEnterBackground = NULL;
    self.willEnterForeground = NULL;
    self.didBecomeActive = NULL;

//    switch (_applicationState) {
//        case UIApplicationStateBackground:
//            [self enterForeground];
//            break;
//
//        case UIApplicationStateInactive:
//            [self becomeActive];
//            break;
//
//        default:
//            break;
//    }
    self.mockApplication = nil;
    
    [super tearDown];
}

#pragma mark - Notifications

- (void)willEnterForeground:(NSNotification*)notification {
    NSLog(@"Test willEnterForeground");
    if (self.willEnterForeground) {
        self.willEnterForeground(notification);
    }
}

- (void)didEnterBackground:(NSNotification*)notification {
    NSLog(@"Test didEnterBackground");
    if (self.didEnterBackground) {
        self.didEnterBackground(notification);
    }
}

- (void)willResignActive:(NSNotification*)notification {
    NSLog(@"Test willResignActive");
    if (self.willResignActive) {
        self.willResignActive(notification);
    }
}

- (void)didBecomeActive:(NSNotification*)notification {
    NSLog(@"Test didBecomeActive");
    if (self.didBecomeActive) {
        self.didBecomeActive(notification);
    }
}

- (MGLMapView *)mapViewForTestWithFrame:(CGRect)rect styleURL:(NSURL *)styleURL {
    MGLBackgroundIntegrationTestMapView *mapView = [[MGLBackgroundIntegrationTestMapView alloc] initWithFrame:rect styleURL:styleURL];
    
    mapView.displayLinkDidUpdate = ^{
        if (self.displayLinkDidUpdate) {
            self.displayLinkDidUpdate();
        }
    };
    
    return mapView;
}

#pragma mark - Tests

- (void)testRendererWhenResigningActive {
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateActive);


    XCTestExpectation *willResignActiveExpectation = [self expectationWithDescription:@"willResignActive"];
    willResignActiveExpectation.expectedFulfillmentCount = 1;
    willResignActiveExpectation.assertForOverFulfill = YES;

    XCTestExpectation *invalidExpectation = [self expectationWithDescription:@"These should not fire"];
    invalidExpectation.inverted = YES;

    __weak typeof(self) weakSelf = self;

    self.willResignActive = ^(NSNotification *) {
        typeof(self) strongSelf = weakSelf;
        MGLMapView *mapView = strongSelf.mapView;

        // Nothing's happened yet.
        MGLTestAssert(strongSelf, !mapView.isDormant);
        MGLTestAssert(strongSelf, mapView.isDisplayLinkActive);

        dispatch_async(dispatch_get_main_queue(), ^{

            // After all notifications, map view should be dormant
            MGLTestAssert(strongSelf, !mapView.isDormant);
            MGLTestAssertNotNil(strongSelf, mapView.displayLink);
            MGLTestAssert(strongSelf, mapView.isDisplayLinkActive);

            [willResignActiveExpectation fulfill];
        });
    };

    self.didEnterBackground = ^(NSNotification *) {
        [invalidExpectation fulfill];
    };

    self.willEnterForeground = ^(NSNotification *) {
        [invalidExpectation fulfill];
    };

    self.didBecomeActive = ^(NSNotification *) {
        [invalidExpectation fulfill];
    };

    [self.mockApplication resignActive];
    [self waitForExpectations:@[willResignActiveExpectation, invalidExpectation] timeout:3.0];

    XCTAssertNotNil(self.mapView.displayLink);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateInactive);
}

- (void)testRendererBecomingActive {
    [self.mockApplication resignActive];

    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateInactive);


    XCTestExpectation *didBecomeActiveExpectation = [self expectationWithDescription:@"didBecomeActive"];
    didBecomeActiveExpectation.expectedFulfillmentCount = 1;
    didBecomeActiveExpectation.assertForOverFulfill = YES;

    XCTestExpectation *invalidExpectation = [self expectationWithDescription:@"These should not fire"];
    invalidExpectation.inverted = YES;

    __weak typeof(self) weakSelf = self;

    self.willResignActive = ^(NSNotification *) {
        [invalidExpectation fulfill];
    };

    self.didEnterBackground = ^(NSNotification *) {
        [invalidExpectation fulfill];
    };

    self.willEnterForeground = ^(NSNotification *) {
        [invalidExpectation fulfill];
    };

    self.didBecomeActive = ^(NSNotification *) {
        typeof(self) strongSelf = weakSelf;
        MGLMapView *mapView = strongSelf.mapView;

        // Nothing's happened yet.
        MGLTestAssert(strongSelf, !mapView.isDormant);
        MGLTestAssert(strongSelf, mapView.isDisplayLinkActive);

        dispatch_async(dispatch_get_main_queue(), ^{

            // After all notifications,
            MGLTestAssert(strongSelf, !mapView.isDormant);
            MGLTestAssert(strongSelf, mapView.isDisplayLinkActive);

            [didBecomeActiveExpectation fulfill];
        });
    };

    [self.mockApplication becomeActive];
    [self waitForExpectations:@[didBecomeActiveExpectation, invalidExpectation] timeout:3.0];

    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateActive);
}

- (void)testRendererWhenGoingIntoBackground {
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateActive);

    __weak typeof(self) weakSelf = self;

    //
    // Enter background
    //
    XCTestExpectation *didEnterBackgroundExpectation = [self expectationWithDescription:@"didEnterBackground"];
    didEnterBackgroundExpectation.expectedFulfillmentCount = 2;
    didEnterBackgroundExpectation.assertForOverFulfill = YES;

    self.willResignActive = ^(NSNotification *) {
        typeof(self) strongSelf = weakSelf;
        MGLMapView *mapView = strongSelf.mapView;

        MGLTestAssertNotNil(strongSelf, mapView.displayLink);
        MGLTestAssert(strongSelf, mapView.isDisplayLinkActive);
        [didEnterBackgroundExpectation fulfill];
    };

    self.didEnterBackground = ^(__unused NSNotification *notification){

        // MGLMapView responds to UIApplicationDidEnterBackgroundNotification and
        // marks the map view as dormant.

        // HOWEVER, depending on the order of creation it's totally possible for
        // client code also responding to this notification to be called first -
        // and then trigger a scenario where GL can be rendering in the
        // background - causing crashes.

        typeof(self) strongSelf = weakSelf;
        MGLMapView *mapView = strongSelf.mapView;

        MGLTestAssert(strongSelf, !mapView.isDormant);
        MGLTestAssertNotNil(strongSelf, mapView.displayLink);

        dispatch_async(dispatch_get_main_queue(), ^{

            // After all notifications, map view should be dormant
            MGLTestAssert(strongSelf, mapView.isDormant);
            MGLTestAssertNil(strongSelf, mapView.displayLink);

            [didEnterBackgroundExpectation fulfill];
        });
    };
    
    [self.mockApplication enterBackground];
    [self waitForExpectations:@[didEnterBackgroundExpectation] timeout:1000.0];
    
    XCTAssert(self.mapView.isDormant);
    
    XCTAssert(!self.mapView.displayLink);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateBackground);

    //
    // Enter foreground
    //

    XCTestExpectation *willEnterForegroundExpectation = [self expectationWithDescription:@"willEnterForeground"];
    willEnterForegroundExpectation.expectedFulfillmentCount = 2;
    willEnterForegroundExpectation.assertForOverFulfill = YES;

    self.willEnterForeground = ^(NSNotification *notification) {

        typeof(self) strongSelf = weakSelf;
        MGLMapView *mapView = strongSelf.mapView;

        MGLTestAssertNil(strongSelf, mapView.displayLink);
        MGLTestAssert(strongSelf,mapView.application.applicationState == UIApplicationStateBackground);

        [willEnterForegroundExpectation fulfill];
    };

    self.didBecomeActive = ^(NSNotification *) {

        typeof(self) strongSelf = weakSelf;
        MGLMapView *mapView = strongSelf.mapView;

        MGLTestAssertNotNil(strongSelf, mapView.displayLink);
        // BECAUSE MAPVIEW NOT YET CALLED
        MGLTestAssert(strongSelf, !mapView.isDisplayLinkActive);
        MGLTestAssert(strongSelf, mapView.application.applicationState == UIApplicationStateActive);

        dispatch_async(dispatch_get_main_queue(), ^{
            MGLTestAssert(strongSelf, mapView.isDisplayLinkActive);
            [willEnterForegroundExpectation fulfill];
        });

    };
    
    [self.mockApplication enterForeground];
    [self waitForExpectations:@[willEnterForegroundExpectation] timeout:1.0];
    
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateActive);
}

- (void)testRendererAdjustingViewsWhenGoingIntoBackground {
    
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateActive);
    
    __weak typeof(self) weakSelf = self;
    
    //
    // Enter background
    //
    
    XCTestExpectation *didEnterBackgroundExpectation = [self expectationWithDescription:@"didEnterBackground"];
    didEnterBackgroundExpectation.expectedFulfillmentCount = 1;
    didEnterBackgroundExpectation.assertForOverFulfill = YES;
    
    __block NSInteger displayLinkCount = 0;
    
    self.displayLinkDidUpdate = ^{
        displayLinkCount++;
    };
    
    self.didEnterBackground = ^(__unused NSNotification *notification){
        typeof(self) strongSelf = weakSelf;
        MGLMapView *mapView = strongSelf.mapView;

        MGLTestAssert(strongSelf, !mapView.isDormant);
        MGLTestAssert(strongSelf, mapView.isDisplayLinkActive);
        
        displayLinkCount = 0;
        
        // Remove the map view, and re-add to try and force a bad situation
        // This will delete/re-create the display link
        UIView *parentView = mapView.superview;
        
        NSLog(@"Removing MGLMapView from super view");
        [mapView removeFromSuperview];
        
        // Re-add
        NSLog(@"Re-adding MGLMapView as child");
        [parentView addSubview:mapView];
        
        MGLTestAssert(strongSelf, displayLinkCount == 0, @"updateDisplayLink was called %ld times", displayLinkCount);
        
        [mapView.topAnchor constraintEqualToAnchor:parentView.topAnchor].active = YES;
        [mapView.leftAnchor constraintEqualToAnchor:parentView.leftAnchor].active = YES;
        [mapView.rightAnchor constraintEqualToAnchor:parentView.rightAnchor].active = YES;
        [mapView.bottomAnchor constraintEqualToAnchor:parentView.bottomAnchor].active = YES;
        
        [didEnterBackgroundExpectation fulfill];
    };
    
    [self.mockApplication enterBackground];
    [self waitForExpectations:@[didEnterBackgroundExpectation] timeout:1.0];
    
    XCTAssert(self.mapView.isDormant);
    
    // TODO: What do we want here?
    XCTAssert(!self.mapView.isDisplayLinkActive);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateBackground);
    
    //
    // Enter foreground
    //
    
    XCTestExpectation *willEnterForegroundExpectation = [self expectationWithDescription:@"willEnterForeground"];
    willEnterForegroundExpectation.expectedFulfillmentCount = 1;
    willEnterForegroundExpectation.assertForOverFulfill = YES;
    
    self.willEnterForeground = ^(NSNotification *notification) {
        displayLinkCount = 0;
        [willEnterForegroundExpectation fulfill];
    };
    
    [self.mockApplication enterForeground];
    XCTAssert(displayLinkCount == 1, @"updateDisplayLink was called %ld times", displayLinkCount);
    [self waitForExpectations:@[willEnterForegroundExpectation] timeout:1.0];
    
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateActive);
}

- (void)testRendererDelayingAdjustingViewsWhenInBackground {
    
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateActive);
    
    __weak typeof(self) weakSelf = self;
    
    //
    // Enter background
    //
    
    XCTestExpectation *didEnterBackgroundExpectation = [self expectationWithDescription:@"didEnterBackground"];
    didEnterBackgroundExpectation.expectedFulfillmentCount = 1;
    didEnterBackgroundExpectation.assertForOverFulfill = YES;

    XCTestExpectation *adjustedViewsExpectation = [self expectationWithDescription:@"adjustedViewsExpectation"];
    adjustedViewsExpectation.expectedFulfillmentCount = 1;
    adjustedViewsExpectation.assertForOverFulfill = YES;

    __block NSInteger displayLinkCount = 0;
    
    self.displayLinkDidUpdate = ^{
        displayLinkCount++;
    };
    
    NSTimeInterval delay = 5.0;
    
    self.didEnterBackground = ^(__unused NSNotification *notification){
        typeof(self) strongSelf = weakSelf;
        MGLMapView *mapView = strongSelf.mapView;
        
        // In general, because order of notifications is not guaranteed
        // the following asserts are somewhat meaningless (don't do this in
        // production) - however, because we're mocking their delivery (and
        // we're tracking a bug)...
        
        // MGLMapView responds to UIApplicationDidEnterBackgroundNotification and
        // marks the map view as dormant. However, depending on the order of
        // creation it's totally possible for client code also responding to
        // this notification to be called first - and then trigger a scenario where
        // GL can be rendering in the background - which can cause crashes.
        
        MGLTestAssert(strongSelf, !mapView.isDormant);
        
        // However, the display should be paused (because this has now moved
        // to ...WillResignActive...
        MGLTestAssert(strongSelf, mapView.isDisplayLinkActive);
        
        // Remove the map view, and re-add to try and force a bad situation
        // This will delete/re-create the display link
        UIView *parentView = mapView.superview;

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

            displayLinkCount = 0;

            NSLog(@"Removing MGLMapView from super view");
            [mapView removeFromSuperview];
        
            // Re-add
            NSLog(@"Re-adding MGLMapView as child");
            [parentView addSubview:mapView];
        
            MGLTestAssert(strongSelf, displayLinkCount == 0, @"updateDisplayLink was called %ld times", displayLinkCount);
        
            [mapView.topAnchor constraintEqualToAnchor:parentView.topAnchor].active = YES;
            [mapView.leftAnchor constraintEqualToAnchor:parentView.leftAnchor].active = YES;
            [mapView.rightAnchor constraintEqualToAnchor:parentView.rightAnchor].active = YES;
            [mapView.bottomAnchor constraintEqualToAnchor:parentView.bottomAnchor].active = YES;
            
            [adjustedViewsExpectation fulfill];
        });

        [didEnterBackgroundExpectation fulfill];
    };
    
    [self.mockApplication enterBackground];
    [self waitForExpectations:@[didEnterBackgroundExpectation] timeout:1.0];
    
    XCTAssert(self.mapView.isDormant);
    
    // TODO: What do we want here?
    XCTAssert(!self.mapView.isDisplayLinkActive);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateBackground);
    
    
    [self waitForExpectations:@[adjustedViewsExpectation] timeout:delay];
    XCTAssert(self.mapView.isDormant);
    XCTAssertFalse(self.mapView.isDisplayLinkActive, @"<%p>.isPaused=%d", self.mapView.displayLink, self.mapView.displayLink.isPaused);

//    [self.mockApplication enterForeground];
}


- (void)testMovingMapViewToNewWindow {
    XCTAssertNotNil(self.mapView.window);
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateActive);
    
    __block NSInteger displayLinkCount = 0;
    
    self.displayLinkDidUpdate = ^{
        displayLinkCount++;
    };

    UIWindow *window = [[UIWindow alloc] initWithFrame:self.mapView.bounds];
    [window addSubview:self.mapView];
    
    XCTAssertEqualObjects(self.mapView.window, window);
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert(displayLinkCount == 1, @"displayLinkCount = %ld", (long)displayLinkCount);
}

// This test requires us to KVO the map view's window.screen, and tear down/setup
// the display link accordingly
- (void)testDisplayLinkWhenMovingMapViewToAnotherScreen {
//
//    [[NSNotificationCenter defaultCenter] addObserverForName:UIScreenDidConnectNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
//        UIScreen *helperScreen = note.object;
//        UIWindow *helperWindow = [[UIWindow alloc] initWithFrame:helperScreen.bounds];
//        helperWindow.screen = helperScreen;
//        UIViewController *helperViewController = [[UIViewController alloc] init];
//        MGLMapView *helperMapView = [[MGLMapView alloc] initWithFrame:helperWindow.bounds styleURL:MGLStyle.satelliteStreetsStyleURL];
//        helperMapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//        helperMapView.camera = self.mapView.camera;
//        helperMapView.compassView.hidden = YES;
//        helperViewController.view = helperMapView;
//        helperWindow.rootViewController = helperViewController;
//        helperWindow.hidden = NO;
//        [self.helperWindows addObject:helperWindow];
//    }];
//    [[NSNotificationCenter defaultCenter] addObserverForName:UIScreenDidDisconnectNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
//        UIScreen *helperScreen = note.object;
//        for (UIWindow *window in self.helperWindows) {
//            if (window.screen == helperScreen) {
//                [self.helperWindows removeObject:window];
//            }
//        }
//    }];
//    var matchingWindowScene: UIWindowScene? = nil
//        let scenes = UIApplication.shared.connectedScenes
//        for item in scenes {
//            if let windowScene = item as? UIWindowScene {
//                if (windowScene.screen == screen) {
//                    matchingWindowScene = windowScene
//                    break
//                }
//                }
//
//

    XCTAssertNotNil(self.mapView.window);
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateActive);

    UIScreen *thisScreen = self.mapView.window.screen;
    UIScreen * _Nonnull otherScreen = nil;
    
    for (UIScreen *screen in [UIScreen screens]) {
        if (screen != thisScreen) {
            otherScreen = screen;
            break;
        }
    }
    
    if (!otherScreen) {
        printf("warning: no secondary screen detected - attempting nil screen\n");
    }
    
    __block NSInteger displayLinkCount = 0;
    
    self.displayLinkDidUpdate = ^{
        displayLinkCount++;
    };

    otherScreen = nil;//[[UIScreen alloc] init];
//    self.mapView.window.screen = otherScreen;
    id oldWindowScene;
    if (@available(iOS 13.0, *)) {
        oldWindowScene = self.mapView.window.windowScene;
        self.mapView.window.windowScene = nil;
    } else {
        // Fallback on earlier versions
        [self.mapView.window setScreen:nil];
    }

    XCTAssertNotNil(self.mapView.window);
    XCTAssert(!self.mapView.isDormant);
    XCTAssert(!self.mapView.isDisplayLinkActive || otherScreen);
    XCTAssert(displayLinkCount == 0);

    displayLinkCount = 0;

    if (@available(iOS 13.0, *)) {
        self.mapView.window.windowScene = oldWindowScene;
    } else {
        // Fallback on earlier versions
        self.mapView.window.screen = thisScreen;
    }

//    self.mapView.window.screen = thisScreen;

    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert(displayLinkCount == 1);
}

// We don't currently include view hierarchy visibility in our notion of "visible"
// so this test will fail at the moment.
- (void)testDisplayLinkWhenHidingMapViewsParentView {

    // Move views around for test
    UIView *mapView = self.mapView;
    UIView *parentView = [[UIView alloc] initWithFrame:mapView.frame];
    UIView *grandParentView = mapView.superview;
    [grandParentView addSubview:parentView];
    [parentView addSubview:mapView];
    
    [mapView.topAnchor constraintEqualToAnchor:parentView.topAnchor].active = YES;
    [mapView.leftAnchor constraintEqualToAnchor:parentView.leftAnchor].active = YES;
    [mapView.rightAnchor constraintEqualToAnchor:parentView.rightAnchor].active = YES;
    [mapView.bottomAnchor constraintEqualToAnchor:parentView.bottomAnchor].active = YES;

    [grandParentView.topAnchor constraintEqualToAnchor:parentView.topAnchor].active = YES;
    [grandParentView.leftAnchor constraintEqualToAnchor:parentView.leftAnchor].active = YES;
    [grandParentView.rightAnchor constraintEqualToAnchor:parentView.rightAnchor].active = YES;
    [grandParentView.bottomAnchor constraintEqualToAnchor:parentView.bottomAnchor].active = YES;

    
    XCTAssertNotNil(self.mapView.window);
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);

    // Hide the parent view
    parentView.hidden = YES;

    XCTAssertFalse(self.mapView.isDormant);
    XCTAssertFalse(self.mapView.isDisplayLinkActive);

    // Show the parent view
    parentView.hidden = NO;
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
}

// We don't currently include view hierarchy visibility in our notion of "visible"
// so this test will fail at the moment.
- (void)testDisplayLinkWhenHidingMapViewsWindow {
    
    XCTAssertNotNil(self.mapView.window);
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    
    // Hide the window
    self.mapView.window.hidden = YES;
    
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssertFalse(self.mapView.isDisplayLinkActive);
    
    // Show the window
    self.mapView.window.hidden = NO;
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
}
@end