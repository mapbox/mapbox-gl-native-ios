#import "MGLNetworkIntegrationManager.h"

#import "MGLLoggingConfiguration_Private.h"
#import "MGLNetworkConfiguration_Private.h"

#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR
#import "MGLAccountManager_Private.h"
#endif

@interface MGLNetworkIntegrationManager ()
@property (atomic) NSURLSession *cachedSession;
@end

@implementation MGLNetworkIntegrationManager

static MGLNetworkIntegrationManager *instance = nil;

+ (MGLNetworkIntegrationManager *)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MGLNetworkIntegrationManager alloc] init];
    });
    return instance;
}

- (void)clearCachedURLSession {
    self.cachedSession = nil;
}

#pragma mark - MGLNativeAppleInterfaceManager delegate -

- (NSURLSession*)session {

    NSURLSession *session = self.cachedSession;

    if (session) {
        return session;
    }

    // Reach out to the public `MGLNetworkConfiguration` manager
    MGLNetworkConfiguration *configuration = [MGLNetworkConfiguration sharedManager];

    if ([configuration respondsToSelector:@selector(session)]) {
        session = [configuration performSelector:@selector(session)];
    }

    if (!session && configuration.sessionConfiguration) {
        session = [NSURLSession sessionWithConfiguration:configuration.sessionConfiguration];
    }

    self.cachedSession = session;

    return session;
}

- (NSURLSessionConfiguration *)sessionConfiguration {
    return [MGLNetworkConfiguration sharedManager].sessionConfiguration;
}

#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR
- (NSString *)skuToken {
    return MGLAccountManager.skuToken;
}
#endif

- (void)startDownloadEvent:(NSString *)event type:(NSString *)type {
    [[MGLNetworkConfiguration sharedManager] startDownloadEvent:event type:@"tile"];
}

- (void)cancelDownloadEventForResponse:(NSURLResponse *)response {
    [[MGLNetworkConfiguration sharedManager] cancelDownloadEventForResponse:response];
}

- (void)stopDownloadEventForResponse:(NSURLResponse *)response {
    [[MGLNetworkConfiguration sharedManager] stopDownloadEventForResponse:response];
}

- (void)debugLog:(NSString *)format, ... {
    MGLLogDebug(format);
}

- (void)errorLog:(NSString *)format, ... {
    MGLLogError(format);
}

@end
