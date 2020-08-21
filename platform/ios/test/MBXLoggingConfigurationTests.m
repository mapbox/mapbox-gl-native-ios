#import <XCTest/XCTest.h>
@import Mapbox;
#import "MGLLoggingConfiguration_Private.h"

@interface MBXLoggingConfigurationTests : XCTestCase
@property (nonatomic, assign) MGLLoggingLevel loggingLevel;
@end

@implementation MBXLoggingConfigurationTests

- (void)setUp {
    self.loggingLevel = [MGLLoggingConfiguration sharedConfiguration].loggingLevel;

    [super setUp];
}

- (void)tearDown {
    [super tearDown];

    [MGLLoggingConfiguration sharedConfiguration].handler = nil;
    [MGLLoggingConfiguration sharedConfiguration].loggingLevel = self.loggingLevel;
}

- (void)internalTestLoggingLevel:(MGLLoggingLevel)level
           expectingLogForLevels:(NSArray*)expectedLevels {

    NSUInteger expectedCount = expectedLevels.count;

    XCTestExpectation *expectation = [self expectationWithDescription:
                                      [NSString stringWithFormat:@"Logging expecting %lu levels", (unsigned long)expectedCount]];
    if (expectedCount > 0) {
        expectation.expectedFulfillmentCount = expectedCount;
    }
    else {
        // If there are no expected levels, we don't expect any logs
        expectation.inverted = YES;
    }

    [MGLLoggingConfiguration sharedConfiguration].loggingLevel = level;

    [MGLLoggingConfiguration sharedConfiguration].handler = ^(MGLLoggingLevel loggingLevel, NSString * _Nonnull filePath, NSUInteger line, NSString * _Nonnull message) {
        NSLog(@"(%lu) Level %ld: %@", (unsigned long)line, (long)loggingLevel, message);
        XCTAssertEqualObjects(message, @(loggingLevel).stringValue);
        XCTAssert([expectedLevels containsObject:@(loggingLevel)]);
        [expectation fulfill];
    };

    MGLLogInfo(@"%d", MGLLoggingLevelInfo);
    MGLLogWarning(@"%d", MGLLoggingLevelWarning);
    MGLLogError(@"%d", MGLLoggingLevelError);
    MGLLogFault(@"%d", MGLLoggingLevelFault);
    MGLLogDebug(@"%d", MGLLoggingLevelDebug);

    [self waitForExpectations:@[expectation] timeout:0.1];
}

- (void)testLoggingLevelNone {
    [self internalTestLoggingLevel:MGLLoggingLevelNone expectingLogForLevels:@[]];
}

- (void)testLoggingLevelDebug {
    [self internalTestLoggingLevel:MGLLoggingLevelDebug
             expectingLogForLevels:@[
        @(MGLLoggingLevelDebug),
        @(MGLLoggingLevelInfo),
        @(MGLLoggingLevelWarning),
        @(MGLLoggingLevelError),
        @(MGLLoggingLevelFault)
    ]];
}

- (void)testLoggingLevelInfo {
    [self internalTestLoggingLevel:MGLLoggingLevelInfo
             expectingLogForLevels:@[
//      @(MGLLoggingLevelDebug),
        @(MGLLoggingLevelInfo),
        @(MGLLoggingLevelWarning),
        @(MGLLoggingLevelError),
        @(MGLLoggingLevelFault)
    ]];
}

- (void)testLoggingLevelWarning {
    [self internalTestLoggingLevel:MGLLoggingLevelWarning
             expectingLogForLevels:@[
//      @(MGLLoggingLevelDebug),
//      @(MGLLoggingLevelInfo),
        @(MGLLoggingLevelWarning),
        @(MGLLoggingLevelError),
        @(MGLLoggingLevelFault)
    ]];
}

- (void)testLoggingLevelError {
    [self internalTestLoggingLevel:MGLLoggingLevelError
             expectingLogForLevels:@[
//      @(MGLLoggingLevelDebug),
//      @(MGLLoggingLevelInfo),
//      @(MGLLoggingLevelWarning),
        @(MGLLoggingLevelError),
        @(MGLLoggingLevelFault)
    ]];
}

- (void)testLoggingLevelFault {
    [self internalTestLoggingLevel:MGLLoggingLevelFault
             expectingLogForLevels:@[
//      @(MGLLoggingLevelDebug),
//      @(MGLLoggingLevelInfo),
//      @(MGLLoggingLevelWarning),
//      @(MGLLoggingLevelError),
        @(MGLLoggingLevelFault)
    ]];
}

- (void)testLoggingLevelVerbose {
    [self internalTestLoggingLevel:MGLLoggingLevelVerbose
             expectingLogForLevels:@[
        @(MGLLoggingLevelDebug),
        @(MGLLoggingLevelInfo),
        @(MGLLoggingLevelWarning),
        @(MGLLoggingLevelError),
        @(MGLLoggingLevelFault)
    ]];
}

- (void)internalTestLoggingExpectedResult:(NSString*)expected withFormat:(id)messageFormat, ... {
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"vaargs test"];
    expectation.expectedFulfillmentCount = 2;

    MGLLoggingConfiguration *logger = [MGLLoggingConfiguration sharedConfiguration];

    logger.loggingLevel = MGLLoggingLevelVerbose;

    logger.handler = ^(MGLLoggingLevel loggingLevel, NSString * _Nonnull filePath, NSUInteger line, NSString * _Nonnull message) {
        NSLog(@"(%lu) Level %ld: %@", (unsigned long)line, (long)loggingLevel, message);
        XCTAssertEqualObjects(message, expected);
        [expectation fulfill];
    };

    va_list formatList;
    va_start(formatList, messageFormat);
    [logger logCallingFunction:__PRETTY_FUNCTION__
                  functionLine:__LINE__
                   messageType:MGLLoggingLevelInfo
                        format:messageFormat
                     arguments:formatList];
    va_end(formatList);

    va_start(formatList, messageFormat);
    [logger logCallingFunction:__PRETTY_FUNCTION__
                  functionLine:__LINE__
                   messageType:MGLLoggingLevelError
                        format:messageFormat
                     arguments:formatList];
    va_end(formatList);
    [self waitForExpectations:@[expectation] timeout:0.1];
}

- (void)testVarArgLogging {
    [self internalTestLoggingExpectedResult:@"hello world 1" withFormat:@"hello %@ %d", @"world", 1];
    [self internalTestLoggingExpectedResult:@"(\n    1,\n    2,\n    3\n)" withFormat:@"%@", @[@1, @2, @3]];
}
@end
