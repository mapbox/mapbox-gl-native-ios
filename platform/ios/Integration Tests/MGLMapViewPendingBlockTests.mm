#import "MGLMapViewIntegrationTest.h"
#import "MGLTestUtility.h"
#import "MGLMapView_Private.h"

@interface MGLMapView (MGLMapViewPendingBlockTests)
@property (nonatomic) NSMutableArray *pendingCompletionBlocks;
- (void)stopDisplayLink;
@end

@interface MGLMapViewPendingBlockTests : MGLMapViewIntegrationTest
@property (nonatomic, copy) void (^observation)(NSDictionary*);
@property (nonatomic) BOOL completionHandlerCalled;
@end

@implementation MGLMapViewPendingBlockTests

- (void)testSetCenterCoordinate {
    [self internal_testSetCenterCoordinate:CLLocationCoordinate2DMake(10.0, 20.0)
                                 zoomLevel:10.0
                                  animated:NO
                                  testName:NSStringFromSelector(_cmd)];
}

- (void)testSetCenterCoordinateAnimated {
    [self internal_testSetCenterCoordinate:CLLocationCoordinate2DMake(10.0, 20.0)
                                 zoomLevel:10.0
                                  animated:NO
                                  testName:NSStringFromSelector(_cmd)];
}

- (void)internal_testSetCenterCoordinate:(CLLocationCoordinate2D)coord
                               zoomLevel:(double)zoomLevel
                                animated:(BOOL)animated
                                testName:(NSString*)testName {
    __typeof__(self) weakSelf = self;
    
    void (^transition)(dispatch_block_t) = ^(dispatch_block_t completion) {
        __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            [strongSelf.mapView setCenterCoordinate:coord
                                          zoomLevel:zoomLevel
                                          direction:0
                                           animated:animated
                                  completionHandler:completion];
        }
        else {
            completion();
        }
    };
    
    [self internalTestCompletionBlockAddedToPendingForTestName:testName
                                                    transition:transition
                                          addToPendingCallback:nil];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void)testSetSameCenterCoordinateBug461 {
    [self internal_testSetSameCenterCoordinateBug461Animated:NO testName:NSStringFromSelector(_cmd)];
}

- (void)testSetSameCenterCoordinateBug461Animated {
    [self internal_testSetSameCenterCoordinateBug461Animated:YES testName:NSStringFromSelector(_cmd)];
}

- (void)internal_testSetSameCenterCoordinateBug461Animated:(BOOL)animated testName:(NSString*)testName {

    CLLocationCoordinate2D coord = CLLocationCoordinate2DMake(10.0, 20.0);
    double zoomLevel = 10.0;
    // Set the map zoom level to a specific constant
    // Set the map center coordinate to a specific constant
    [self.mapView setCenterCoordinate:coord
                            zoomLevel:zoomLevel
                             animated:NO];

    [self.mapView setNeedsRerender];
    [self waitForMapViewToIdleWithTimeout:1];

    XCTAssert(self.mapView.zoomLevel == zoomLevel);
    XCTAssertEqualWithAccuracy(self.mapView.centerCoordinate.latitude, coord.latitude, 0.000001);
    XCTAssertEqualWithAccuracy(self.mapView.centerCoordinate.longitude, coord.longitude, 0.000001);

    [self internal_testSetCenterCoordinate:coord
                                 zoomLevel:zoomLevel
                                  animated:NO
                                  testName:testName];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void)testSetVisibleCoordinateBounds {
    [self internal_testSetVisibleCoordinateBoundsAnimated:NO testName:NSStringFromSelector(_cmd)];
}

- (void)testSetVisibleCoordinateBoundsAnimated {
    [self internal_testSetVisibleCoordinateBoundsAnimated:YES testName:NSStringFromSelector(_cmd)];
}

- (void)internal_testSetVisibleCoordinateBoundsAnimated:(BOOL)animated testName:(NSString*)testName {
    __typeof__(self) weakSelf = self;
    
    void (^transition)(dispatch_block_t) = ^(dispatch_block_t completion) {
        __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            MGLCoordinateBounds unitBounds = MGLCoordinateBoundsMake(CLLocationCoordinate2DMake(0, 0), CLLocationCoordinate2DMake(1, 1));
            [strongSelf.mapView setVisibleCoordinateBounds:unitBounds
                                               edgePadding:UIEdgeInsetsZero
                                                  animated:animated
                                         completionHandler:completion];
        }
        else {
            completion();
        }
    };
    
    [self internalTestCompletionBlockAddedToPendingForTestName:testName
                                                    transition:transition
                                          addToPendingCallback:nil];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void)testSetCamera {
    [self internal_testSetCameraAnimated:NO testName:NSStringFromSelector(_cmd)];
}

- (void)testSetCameraAnimated {
    [self internal_testSetCameraAnimated:YES testName:NSStringFromSelector(_cmd)];
}

- (void)internal_testSetCameraAnimated:(BOOL)animated testName:(NSString*)testName {
    __typeof__(self) weakSelf = self;
    
    void (^transition)(dispatch_block_t) = ^(dispatch_block_t completion) {
        __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            MGLCoordinateBounds unitBounds = MGLCoordinateBoundsMake(CLLocationCoordinate2DMake(0, 0), CLLocationCoordinate2DMake(1, 1));
            MGLMapCamera *camera = [strongSelf.mapView cameraThatFitsCoordinateBounds:unitBounds];
            
            [strongSelf.mapView setCamera:camera
                             withDuration:animated ? 0.3 : 0.0
                  animationTimingFunction:nil
                        completionHandler:completion];
        }
        else {
            completion();
        }
    };
    
    [self internalTestCompletionBlockAddedToPendingForTestName:testName
                                                    transition:transition
                                          addToPendingCallback:nil];
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

- (void)testFlyToCamera {
    [self internal_testFlyToCameraAnimated:NO testName:NSStringFromSelector(_cmd)];
}

- (void)testFlyToCameraAnimated {
    [self internal_testFlyToCameraAnimated:YES testName:NSStringFromSelector(_cmd)];
}

- (void)internal_testFlyToCameraAnimated:(BOOL)animated testName:(NSString*)testName {
    
    __typeof__(self) weakSelf = self;

    void (^transition)(dispatch_block_t) = ^(dispatch_block_t completion) {
        __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            MGLCoordinateBounds unitBounds = MGLCoordinateBoundsMake(CLLocationCoordinate2DMake(0, 0), CLLocationCoordinate2DMake(1, 1));
            MGLMapCamera *camera = [strongSelf.mapView cameraThatFitsCoordinateBounds:unitBounds];
            
            [strongSelf.mapView flyToCamera:camera
                               withDuration:animated ? 0.3 : 0.0
                          completionHandler:completion];
        }
        else {
            completion();
        }
    };
    
    [self internalTestCompletionBlockAddedToPendingForTestName:testName
                                                    transition:transition
                                          addToPendingCallback:nil];
}

#pragma mark - test interrupting regular rendering

- (void)testSetCenterCoordinateSetHidden {
    
    __typeof__(self) weakSelf = self;
    
    void (^transition)(dispatch_block_t) = ^(dispatch_block_t completion) {
        __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            [strongSelf.mapView setCenterCoordinate:CLLocationCoordinate2DMake(10.0, 10.0)
                                          zoomLevel:10.0
                                          direction:0
                                           animated:NO
                                  completionHandler:completion];
        }
        else {
            completion();
        }
    };
    
    dispatch_block_t addedToPending = ^{
        __typeof__(self) strongSelf = weakSelf;

        MGLTestAssert(strongSelf, !strongSelf.completionHandlerCalled);
        
        // Now hide the mapview
        strongSelf.mapView.hidden = YES;
        
        MGLTestAssert(strongSelf, strongSelf.completionHandlerCalled);
    };
    
    [self internalTestCompletionBlockAddedToPendingForTestName:NSStringFromSelector(_cmd)
                                                    transition:transition
                                          addToPendingCallback:addedToPending];
}

- (void)testSetCenterCoordinatePauseRendering {
    
    __typeof__(self) weakSelf = self;
    
    void (^transition)(dispatch_block_t) = ^(dispatch_block_t completion) {
        __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            [strongSelf.mapView setCenterCoordinate:CLLocationCoordinate2DMake(10.0, 10.0)
                                          zoomLevel:10.0
                                          direction:0
                                           animated:NO
                                  completionHandler:completion];
        }
        else {
            completion();
        }
    };
    
    dispatch_block_t addedToPending = ^{
        __typeof__(self) strongSelf = weakSelf;
        
        MGLTestAssert(strongSelf, !strongSelf.completionHandlerCalled);
        
        // Stopping display link, should trigger the pending blocks
        [strongSelf.mapView stopDisplayLink];
        
        MGLTestAssert(strongSelf, strongSelf.completionHandlerCalled);
    };
    
    [self internalTestCompletionBlockAddedToPendingForTestName:NSStringFromSelector(_cmd)
                                                    transition:transition
                                          addToPendingCallback:addedToPending];
}

- (void)testSetCenterCoordinateRemoveFromSuperview {
    
    __typeof__(self) weakSelf = self;
    
    void (^transition)(dispatch_block_t) = ^(dispatch_block_t completion) {
        __typeof__(self) strongSelf = weakSelf;
        
        if (strongSelf) {
            [strongSelf.mapView setCenterCoordinate:CLLocationCoordinate2DMake(10.0, 10.0)
                                          zoomLevel:10.0
                                          direction:0
                                           animated:NO
                                  completionHandler:completion];
        }
        else {
            completion();
        }
    };
    
    dispatch_block_t addedToPending = ^{
        __typeof__(self) strongSelf = weakSelf;
        
        MGLTestAssert(strongSelf, !strongSelf.completionHandlerCalled);
        
        // Remove from window, triggering validateDisplayLink
        [strongSelf.mapView removeFromSuperview];
        
        MGLTestAssert(strongSelf, strongSelf.completionHandlerCalled);
    };
    
    [self internalTestCompletionBlockAddedToPendingForTestName:NSStringFromSelector(_cmd)
                                                    transition:transition
                                          addToPendingCallback:addedToPending];
}

#pragma mark - Shared utility methods

- (void)internalTestCompletionBlockAddedToPendingForTestName:(NSString *)testName
                                                  transition:(void (^)(dispatch_block_t))transition
                                        addToPendingCallback:(dispatch_block_t)addToPendingCallback {
    
    XCTestExpectation *expectation = [self expectationWithDescription:testName];
    
    __weak __typeof__(self) myself = self;
    
    dispatch_block_t block = ^{
        myself.completionHandlerCalled = YES;
        [expectation fulfill];
    };
    
    XCTAssertNotNil(transition);
    transition(block);
    
    XCTAssert(!self.completionHandlerCalled);
    XCTAssert(self.mapView.pendingCompletionBlocks.count == 0);
    
    __block BOOL blockAddedToPendingBlocks = NO;
    
    // Observes changes to pendingCompletionBlocks (including additions)
    self.observation = ^(NSDictionary *change){

        NSLog(@"change = %@ count = %lu", change, (unsigned long)myself.mapView.pendingCompletionBlocks.count);

        NSArray *value = change[NSKeyValueChangeNewKey];
        
        MGLTestAssert(myself, [value isKindOfClass:[NSArray class]]);
        
        if (value.count > 0) {
            MGLTestAssert(myself, [value containsObject:block]);            
            MGLTestAssert(myself, !blockAddedToPendingBlocks);
            if ([myself.mapView.pendingCompletionBlocks containsObject:block]) {
                blockAddedToPendingBlocks = YES;
                
                if (addToPendingCallback) {
                    addToPendingCallback();
                }
            }
        }
    };
    
    [self.mapView addObserver:self forKeyPath:@"pendingCompletionBlocks" options:NSKeyValueObservingOptionNew context:_cmd];
    
    [self waitForExpectations:@[expectation] timeout:0.5];
    
    XCTAssert(blockAddedToPendingBlocks);
    XCTAssert(self.completionHandlerCalled);
    XCTAssert(self.mapView.pendingCompletionBlocks.count == 0);
    
    [self.mapView removeObserver:self forKeyPath:@"pendingCompletionBlocks" context:_cmd];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (self.observation) {
        self.observation(change);
    }
}
@end
