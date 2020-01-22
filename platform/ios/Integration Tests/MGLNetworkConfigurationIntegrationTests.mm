#import <XCTest/XCTest.h>
#import "MGLNetworkIntegrationManager.h"
#import "MGLNetworkConfiguration.h"
#import "MGLNetworkConfiguration_Private.h"
#import "MGLOfflineStorage_Private.h"
#import "MGLMapView.h"

@interface MGLNetworkConfigurationIntegrationTests : XCTestCase
@end

// NOTE: These tests are currently assumed to run in this specific order.
@implementation MGLNetworkConfigurationIntegrationTests

- (void)setUp {
    [super setUp];

    // Reset before each test
    [MGLNativeNetworkManager sharedManager].delegate = nil;
}

- (void)testNativeNetworkManagerDelegateIsSet
{
    XCTAssertNil([MGLNativeNetworkManager sharedManager].delegate);
    [MGLNetworkConfiguration setNativeNetworkManagerDelegateToDefault];
    XCTAssertNotNil([MGLNativeNetworkManager sharedManager].delegate);
}

- (void)testNativeNetworkManagerDelegateIsNotSetBySharedManager
{
    XCTAssertNil([MGLNativeNetworkManager sharedManager].delegate);

    // Just calling the shared manager is not sufficient (since it's a singleton,
    // and created with a dispatch_once).
    [MGLNetworkConfiguration sharedManager];
    XCTAssertNil([MGLNativeNetworkManager sharedManager].delegate);
}

- (void)testNativeNetworkManagerDelegateIsSetBySharedOfflineStorage
{
    XCTAssertNil([MGLNativeNetworkManager sharedManager].delegate);

    // However, to compare with testNativeNetworkManagerDelegateIsNotSetBySharedManager
    // the first time `[MGLOfflineStorage sharedOfflineStorage]` is called, it
    // *will* set the delegate.
    //
    // But the same reason (dispatch_once), if the singleton is cleared, and then
    // `sharedOfflineStorage` is called again, it will not be set.
    //
    // `MGLNativeNetworkManager` is not exposed publicly, so this is more of a
    // warning.
    [MGLOfflineStorage sharedOfflineStorage];
    XCTAssertNotNil([MGLNativeNetworkManager sharedManager].delegate);
}

- (void)testNativeNetworkManagerDelegateIsNotSetBySharedOfflineStorageASecondTime
{
    // As noted above, a second attempt though will break it.
    XCTAssertNil([MGLNativeNetworkManager sharedManager].delegate);
    [MGLOfflineStorage sharedOfflineStorage];
    XCTAssertNil([MGLNativeNetworkManager sharedManager].delegate);
}

- (void)testNativeNetworkManagerDelegateIsSetByMapViewInit
{
    XCTAssertNil([MGLNativeNetworkManager sharedManager].delegate);
    (void)[[MGLMapView alloc] init];
    XCTAssertNotNil([MGLNativeNetworkManager sharedManager].delegate);
}

@end
