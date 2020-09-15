#import "MGLMapViewIntegrationTest.h"
#import "MGLMockApplication.h"
#import "MGLMapView_Private.h"

@interface MGLMapView (BackgroundTests)
@property (nonatomic, weak) id<MGLApplication> application;
@property (nonatomic, getter=isDormant) BOOL dormant;
@property (nonatomic, readonly, getter=isDisplayLinkActive) BOOL displayLinkActive;
@property (nonatomic) CADisplayLink *displayLink;
@property (nonatomic) NSMutableArray *pendingCompletionBlocks;
- (BOOL)isVisible;
- (void)updateFromDisplayLink:(CADisplayLink *)displayLink;
- (BOOL)renderSync;
@end

@protocol MGLApplication;

typedef void (^MGLNotificationBlock)(NSNotification*);

#pragma mark - MGLBackgroundIntegrationTestMapView

@interface MGLBackgroundIntegrationTestMapView : MGLMapView
@property (nonatomic, assign) BOOL rendered;
@property (nonatomic, copy) dispatch_block_t displayLinkDidUpdate;
@property (nonatomic, copy) dispatch_block_t renderSyncBlock;
@end

@implementation MGLBackgroundIntegrationTestMapView
- (void)updateFromDisplayLink:(CADisplayLink *)displayLink {
    [super updateFromDisplayLink:displayLink];
    
    if (self.displayLinkDidUpdate) {
        self.displayLinkDidUpdate();
    }
}

- (BOOL)renderSync {
    BOOL result = [super renderSync];
    if (result) {
        self.rendered = result;
    }
    return result;
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
    [MGLLoggingConfiguration sharedConfiguration].loggingLevel = MGLLoggingLevelDebug;
    self.mockApplication = [[MGLMockApplication alloc] init];

    // Register notifications *BEFORE* MGLMapView does.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:self.mockApplication];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:self.mockApplication];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive:) name:UIApplicationWillResignActiveNotification object:self.mockApplication];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:self.mockApplication];

    [super setUp];

    // TODO: Add observers after setUp, so that the dispatch_async blocks in the
    // tests below are clearer.

    // Now override
    self.mapView.application = self.mockApplication;
}

- (void)tearDown {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.willResignActive = NULL;
    self.didEnterBackground = NULL;
    self.willEnterForeground = NULL;
    self.didBecomeActive = NULL;

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

- (void)testDisplayLinkIsActive {

    MGLBackgroundIntegrationTestMapView *mapView = (MGLBackgroundIntegrationTestMapView *)self.mapView;
    XCTAssert([mapView isKindOfClass:[MGLBackgroundIntegrationTestMapView class]]);

    XCTAssertFalse(mapView.isDormant);
    XCTAssert(mapView.isDisplayLinkActive);
    XCTAssert(mapView.application.applicationState == UIApplicationStateActive);
    XCTAssert(mapView.rendered);
}

- (void)testLoadingMapViewFromStoryboard {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Test" bundle:[NSBundle mainBundle]];
    UIViewController *vc = [storyboard instantiateInitialViewController];

    MGLBackgroundIntegrationTestMapView *mapView2 = (MGLBackgroundIntegrationTestMapView*)vc.view;
    XCTAssert([mapView2 isKindOfClass:[MGLBackgroundIntegrationTestMapView class]]);

    XCTAssertFalse(mapView2.isDormant);
    XCTAssertNil(mapView2.displayLink);

    // This is NOT the mock application
    XCTAssert(mapView2.application != self.mapView.application);
    XCTAssert(mapView2.application.applicationState == UIApplicationStateActive);
    XCTAssertFalse(mapView2.rendered);

    __block NSInteger displayLinkCount = 0;

    mapView2.displayLinkDidUpdate = ^{
        displayLinkCount++;
    };

    [self.window addSubview:mapView2];

    XCTAssert(displayLinkCount == 1);
    XCTAssertFalse(mapView2.rendered);
    XCTAssertFalse(mapView2.isDormant);
    XCTAssert(mapView2.isDisplayLinkActive);

    // Wait
    __weak typeof(self) weakSelf = self;

    XCTestExpectation *expect = [self expectationWithDescription:@"Map view is rendered after adding to subview"];
    dispatch_async(dispatch_get_main_queue(), ^{
        MGLTestAssert(weakSelf, mapView2.rendered, @"");
        [expect fulfill];
    });

    [self waitForExpectations:@[expect] timeout:1.0];

    [mapView2 removeFromSuperview];

    XCTAssertFalse(mapView2.isDormant);
    XCTAssertNil(mapView2.displayLink);
    
    mapView2 = nil;
}

- (void)testDisplayLinkRerenderLogic {
    MGLBackgroundIntegrationTestMapView *mapView = (MGLBackgroundIntegrationTestMapView *)self.mapView;

    __block NSInteger displayLinkCount = 0;

    self.displayLinkDidUpdate = ^{
        displayLinkCount++;
    };

    mapView.rendered = NO;
    [mapView setNeedsRerender];

    XCTAssert(mapView.needsDisplayRefresh);
    XCTAssert(displayLinkCount == 0);
    XCTAssertFalse(mapView.rendered);

    // Simulate a display link tick, to force a setNeedsDisplay
    [mapView updateFromDisplayLink:nil];

    XCTAssert(displayLinkCount == 1);
    XCTAssert(mapView.needsDisplayRefresh); // Requested render...
    XCTAssertFalse(mapView.rendered); // ...but not yet rendered

    XCTestExpectation *renderExpectation = [self expectationWithDescription:@"Map view should have been rendered"];

    __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{

            // After all notifications, map view should be dormant
            MGLTestAssert(weakSelf, displayLinkCount == 1);
            MGLTestAssert(weakSelf, mapView.rendered);

            // This is YES because the *previous* render call, triggers
            // `MGLRenderFrontend::update`, itself triggering
            // `-[MGLMapView setNeedsRerender]`. If this fails, that's ok, remove
            // the check.
            MGLTestAssert(weakSelf, mapView.needsDisplayRefresh);

            mapView.rendered = NO;
            [renderExpectation fulfill];
        });

    [self waitForExpectations:@[renderExpectation] timeout:0.05];

    XCTAssert(displayLinkCount == 1);
    XCTAssertFalse(mapView.rendered);
}

- (void)testRendererWhenResigningActive {
    XCTestExpectation *willResignActiveExpectation = [self expectationWithDescription:@"Rendering state after resigning active"];
    willResignActiveExpectation.expectedFulfillmentCount = 1;
    willResignActiveExpectation.assertForOverFulfill = YES;

    XCTestExpectation *invalidExpectation = [self expectationWithDescription:@"Other callbacks should not fire"];
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

            if (strongSelf.mapView.renderingInInactiveStateEnabled) {
                MGLTestAssert(strongSelf, mapView.isDisplayLinkActive);
            }
            else {
                MGLTestAssert(strongSelf, !mapView.isDisplayLinkActive);
            }

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
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateInactive);

    if (self.mapView.renderingInInactiveStateEnabled) {
        XCTAssert(self.mapView.isDisplayLinkActive);
    }
    else {
        XCTAssert(self.mapView.isDisplayLinkActive);
    }
}

- (void)testRendererBecomingActive {
    [self.mockApplication resignActive];

    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateInactive);

    if (self.mapView.renderingInInactiveStateEnabled) {
        XCTAssert(self.mapView.isDisplayLinkActive);
    }
    else {
        XCTAssertFalse(self.mapView.isDisplayLinkActive);
    }

    XCTestExpectation *didBecomeActiveExpectation = [self expectationWithDescription:@"Rendering state after becoming active"];
    didBecomeActiveExpectation.expectedFulfillmentCount = 1;
    didBecomeActiveExpectation.assertForOverFulfill = YES;

    XCTestExpectation *invalidExpectation = [self expectationWithDescription:@"Other callbacks should not fire"];
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

        if (strongSelf.mapView.renderingInInactiveStateEnabled) {
            MGLTestAssert(strongSelf, strongSelf.mapView.isDisplayLinkActive);
        }
        else {
            MGLTestAssert(strongSelf, !strongSelf.mapView.isDisplayLinkActive);
        }

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
    XCTestExpectation *didEnterBackgroundExpectation = [self expectationWithDescription:@"Rendering state on entering background"];
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

    XCTestExpectation *willEnterForegroundExpectation = [self expectationWithDescription:@"Rendering state on entering foreground"];
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
        MGLTestAssert(strongSelf, mapView.application.applicationState == UIApplicationStateActive);

        if (strongSelf.mapView.renderingInInactiveStateEnabled) {
            MGLTestAssert(strongSelf, mapView.isDisplayLinkActive);
        }
        else {
            MGLTestAssert(strongSelf, !mapView.isDisplayLinkActive);
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            MGLTestAssertNotNil(strongSelf, mapView.displayLink);
            MGLTestAssert(strongSelf, mapView.isDisplayLinkActive);
            [willEnterForegroundExpectation fulfill];
        });

    };
    
    [self.mockApplication enterForeground];
    [self waitForExpectations:@[willEnterForegroundExpectation] timeout:1.0];
    
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssertNotNil(self.mapView.displayLink);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateActive);
}

- (void)testKillingRendererAfterSetNeedsRerender {

    MGLBackgroundIntegrationTestMapView *mapView = (MGLBackgroundIntegrationTestMapView *)self.mapView;

    __block NSInteger displayLinkCount = 0;
    __block BOOL pendingBlockCalled = NO;

    self.displayLinkDidUpdate = ^{
        displayLinkCount++;
    };

    mapView.rendered = NO;

    [mapView.pendingCompletionBlocks addObject:^{
        pendingBlockCalled = YES;
    }];

    [mapView setNeedsRerender];
    XCTAssert(mapView.needsDisplayRefresh);

    XCTAssert(displayLinkCount == 0);
    XCTAssertFalse(mapView.rendered);
    XCTAssertFalse(pendingBlockCalled);

    // Simulate a display link tick, to force a setNeedsDisplay
    [mapView updateFromDisplayLink:nil];

    XCTAssert(displayLinkCount == 1);
    XCTAssertFalse(mapView.rendered); // Display link has ticked but no render
    XCTAssertFalse(pendingBlockCalled);
    XCTAssert(mapView.needsDisplayRefresh);

    // Now kill the display link
    UIView *parent = mapView.superview;
    [mapView removeFromSuperview];

    XCTAssert(displayLinkCount == 1);
    XCTAssertFalse(mapView.rendered); // Display link has ticked but no render
    XCTAssert(pendingBlockCalled); // BUT we have called our pending block
    XCTAssert(mapView.pendingCompletionBlocks.count == 0);
    XCTAssertFalse(mapView.needsDisplayRefresh);


    XCTestExpectation *renderExpectation = [self expectationWithDescription:@"After removing the map view, there should be no rendering"];

    __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            MGLTestAssert(weakSelf, !mapView.isDormant);
            MGLTestAssert(weakSelf, displayLinkCount == 1, @"Display link should not update");
            MGLTestAssert(weakSelf, !mapView.rendered); // NO RENDERING
            MGLTestAssert(weakSelf, mapView.pendingCompletionBlocks.count == 0);

            mapView.rendered = NO;
            [renderExpectation fulfill];
        });

    [self waitForExpectations:@[renderExpectation] timeout:0.05];

    XCTAssert(displayLinkCount == 1);
    XCTAssertFalse(mapView.rendered);
    XCTAssertFalse(mapView.needsDisplayRefresh);

    // Re-add the view
    [parent addSubview:mapView];

    XCTAssert(mapView.needsDisplayRefresh);
    XCTAssert(!mapView.isDormant);
    XCTAssert(displayLinkCount == 2); // updateFromDisplayLink is called on creation
    XCTAssertFalse(mapView.rendered); // but no render yet.
    XCTAssert(mapView.isDisplayLinkActive);

    renderExpectation = [self expectationWithDescription:@"After adding the view, map should have rendered"];

        dispatch_async(dispatch_get_main_queue(), ^{
            MGLTestAssert(weakSelf, mapView.isDisplayLinkActive);
            MGLTestAssert(weakSelf, mapView.rendered);
            [renderExpectation fulfill];
        });

    [self waitForExpectations:@[renderExpectation] timeout:0.05];
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

        if (strongSelf.mapView.renderingInInactiveStateEnabled) {
            MGLTestAssert(strongSelf, strongSelf.mapView.isDisplayLinkActive);
        }
        else {
            MGLTestAssert(strongSelf, !strongSelf.mapView.isDisplayLinkActive);
        }

        displayLinkCount = 0;
        
        // Remove the map view, and re-add to try and force a bad situation
        // This will delete/re-create the display link
        UIView *parentView = mapView.superview;
        
        NSLog(@"Remove and re-add view");
        [mapView removeFromSuperview];
        [parentView addSubview:mapView];
        
        MGLTestAssert(strongSelf, displayLinkCount == 0, @"updateDisplayLink was called %ld times", (long)displayLinkCount);
        
        [mapView.topAnchor constraintEqualToAnchor:parentView.topAnchor].active = YES;
        [mapView.leftAnchor constraintEqualToAnchor:parentView.leftAnchor].active = YES;
        [mapView.rightAnchor constraintEqualToAnchor:parentView.rightAnchor].active = YES;
        [mapView.bottomAnchor constraintEqualToAnchor:parentView.bottomAnchor].active = YES;
        
        [didEnterBackgroundExpectation fulfill];
    };
    
    [self.mockApplication enterBackground];
    [self waitForExpectations:@[didEnterBackgroundExpectation] timeout:1.0];
    
    XCTAssert(self.mapView.isDormant);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateBackground);
    XCTAssertFalse(self.mapView.isDisplayLinkActive);

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
    XCTAssert(displayLinkCount == 1, @"updateDisplayLink was called %ld times", (long)displayLinkCount);
    [self waitForExpectations:@[willEnterForegroundExpectation] timeout:1.0];
    
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateActive);
}

- (void)testRendererPresentVCAndEnterBackground {

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Test" bundle:[NSBundle mainBundle]];
    UINavigationController *nc = [storyboard instantiateViewControllerWithIdentifier:@"NavigationControllerId"];
    XCTAssertNotNil(nc);

    UIViewController *root = self.window.rootViewController;
    [root presentViewController:nc animated:NO completion:NULL];

    // Currently, present a view controller over the top of the map view will
    // NOT pause the mapview. This is really an application specific problem.
    // In this case, use MGLMapView.hidden to stop rendering.

    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateActive);
    XCTAssert([self.mapView isVisible]);

    [self.mockApplication enterBackground];
    [self.mockApplication enterForeground];

    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateActive);
    XCTAssert([self.mapView isVisible]);
}

- (void)testRendererRemoveFromWindowThenBackground {

    UIView *parent = self.mapView.superview;

    [self.mapView removeFromSuperview];

    XCTAssertFalse(self.mapView.isDormant);
    XCTAssertNil(self.mapView.displayLink);
    XCTAssertFalse([self.mapView isVisible]);

    [self.mockApplication enterBackground];
    XCTAssert(self.mapView.isDormant);
    [self.mockApplication enterForeground];

    XCTAssertFalse(self.mapView.isDormant);
    XCTAssertNil(self.mapView.displayLink);
    XCTAssertFalse([self.mapView isVisible]);

    [parent addSubview:self.mapView];

    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert([self.mapView isVisible]);
}

- (void)testRendererBackgroundThenAddSubview {

    UIView *parent = self.mapView.superview;

    [self.mapView removeFromSuperview];

    XCTAssertFalse(self.mapView.isDormant);
    XCTAssertNil(self.mapView.displayLink);
    XCTAssertFalse([self.mapView isVisible]);

    [self.mockApplication enterBackground];
    XCTAssert(self.mapView.isDormant);

    [parent addSubview:self.mapView];

    XCTAssert(self.mapView.isDormant);
    XCTAssertNil(self.mapView.displayLink);

    // Map view is considered visible, even though the application is backgrounded.
    XCTAssert([self.mapView isVisible]);

    [self.mockApplication enterForeground];

    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert([self.mapView isVisible]);
}

- (void)testRendererRemoveFromWindowThenBackground2 {
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssertNotNil(self.mapView.displayLink);
    XCTAssert([self.mapView isVisible]);

    [self.mockApplication enterBackground];
    XCTAssert(self.mapView.isDormant);
    [self.mockApplication enterForeground];

    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert([self.mapView isVisible]);
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
        
            MGLTestAssert(strongSelf, displayLinkCount == 0, @"updateDisplayLink was called %ld times", (long)displayLinkCount);
        
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

    [self waitForExpectations:@[adjustedViewsExpectation] timeout:delay+1.0];
    XCTAssert(self.mapView.isDormant);
    XCTAssertFalse(self.mapView.isDisplayLinkActive, @"<%p>.isPaused=%d", self.mapView.displayLink, self.mapView.displayLink.isPaused);
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

- (void)testDisplayLinkWhenMovingMapViewToAnExternalUIScreen {
    XCTAssertNotNil(self.mapView.window);
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateActive);

    // Test iOS < 13
    if (@available(iOS 13, *)) {
        XCTSkip(@"This test requires an iOS version < 13");
    }

    UIScreen *thisScreen = self.mapView.window.screen;
    UIScreen *otherScreen = nil;

    for (UIScreen *screen in [UIScreen screens]) {
        if (screen != thisScreen) {
            otherScreen = screen;
            break;
        }
    }

    if (!otherScreen) {
        XCTSkip(@"warning: no secondary screen detected.");
    }

    __block NSInteger displayLinkCount = 0;

    self.displayLinkDidUpdate = ^{
        displayLinkCount++;
    };

    self.mapView.window.screen = otherScreen;

    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert(displayLinkCount == 1);

    // Revert back
    displayLinkCount = 0;
    self.mapView.window.screen = thisScreen;

    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert(displayLinkCount == 1);
}

- (void)testDisplayLinkWhenMovingMapViewToANilWindowScene🙁 {
    // This test is currently disabled, since the SDK doesn't fully support
    // changing the map view via UIWindowScene
    [self internalTestDisplayLinkWhenMovingMapViewToExternalWindowScene:NO];
}

- (void)testDisplayLinkWhenMovingMapViewToAnExternalWindowScene🙁 {
    // This test is currently disabled, since the SDK doesn't fully support
    // changing the map view via UIWindowScene
    [self internalTestDisplayLinkWhenMovingMapViewToExternalWindowScene:YES];
}

- (void)internalTestDisplayLinkWhenMovingMapViewToExternalWindowScene:(BOOL)useExternalWindowScene {
    XCTAssertNotNil(self.mapView.window);
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    XCTAssert(self.mapView.application.applicationState == UIApplicationStateActive);

    // Test iOS < 13
    if (@available(iOS 13, *)) {

        UIScreen *thisScreen = self.mapView.window.screen;

        UIWindowScene *thisWindowScene;
        UIWindowScene *otherWindowScene;

        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = ((UIWindowScene*)scene);
                UIScreen *windowSceneScreen = windowScene.screen;

                if (windowSceneScreen == thisScreen) {
                    thisWindowScene = windowScene;
                }
                else if (useExternalWindowScene) {
                    otherWindowScene = windowScene;
                }
            }
        }
        XCTAssertNotNil(thisWindowScene);

        if (useExternalWindowScene && !otherWindowScene) {
            XCTSkip(@"warning: no secondary screen detected.");
        }

        __block NSInteger displayLinkCount = 0;

        self.displayLinkDidUpdate = ^{
            displayLinkCount++;
        };

        self.mapView.window.windowScene = otherWindowScene;

        XCTAssertFalse(self.mapView.isDormant);

        if (otherWindowScene) {
            XCTAssert(self.mapView.isDisplayLinkActive);
            XCTAssert(displayLinkCount == 1);
        }
        else {
            XCTAssertFalse(self.mapView.isDisplayLinkActive);
            XCTAssert(displayLinkCount == 0);
        }

        // Revert back
        displayLinkCount = 0;
        self.mapView.window.windowScene = thisWindowScene;

        XCTAssertFalse(self.mapView.isDormant);
        XCTAssert(self.mapView.isDisplayLinkActive);
        XCTAssert(displayLinkCount == 1);
    }
    else {
        XCTSkip(@"This test requires iOS 13+");
    }
}

// We don't currently include view hierarchy visibility in our notion of "visible"
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

    // We don't detect parent view's hidden state changing
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);

    [parentView removeFromSuperview];

    // But we removed it, so should go invalid
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssertFalse(self.mapView.isDisplayLinkActive);

    // Re-adding
    [grandParentView addSubview:parentView];

    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);

    // Show the parent view
    parentView.hidden = NO;

    // Again no change.
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
}

// We don't currently include view hierarchy visibility in our notion of "visible"
- (void)testDisplayLinkWhenHidingMapViewsWindow {
    
    XCTAssertNotNil(self.mapView.window);
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    
    // Hide the window
    self.mapView.window.hidden = YES;
    
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
    
    // Show the window
    self.mapView.window.hidden = NO;
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);

    // Now remove from the window
    UIView *parent = self.mapView.superview;
    [parent removeFromSuperview];

    XCTAssertNil(self.mapView.window);
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssertFalse(self.mapView.isDisplayLinkActive);

    // Re-add
    [self.window addSubview:parent];

    XCTAssertNotNil(self.mapView.window);
    XCTAssertFalse(self.mapView.isDormant);
    XCTAssert(self.mapView.isDisplayLinkActive);
}

@end
