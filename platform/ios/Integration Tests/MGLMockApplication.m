#import "MGLMockApplication.h"

#define TRACE() NSLog(@"%s", __PRETTY_FUNCTION__)

@implementation MGLMockApplication

- (void)dealloc {
    if (_applicationState != UIApplicationStateActive) {
        [self enterForeground];
    }
}

- (instancetype)init {
    if ((self = [super init])) {
        _applicationState = UIApplicationStateActive;
    }
    return self;
}

- (void)enterBackground {
    TRACE();
    self.applicationState = UIApplicationStateInactive;
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillResignActiveNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:self];
    self.applicationState = UIApplicationStateBackground;
}

- (void)enterForeground {
    TRACE();
    self.applicationState = UIApplicationStateInactive;
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:self];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:self];
    self.applicationState = UIApplicationStateActive;
}

#pragma mark - MGLApplicationProxy

@synthesize applicationState = _applicationState;
@synthesize statusBarOrientation = _statusBarOrientation;

- (void)mgl_openURL:(nonnull NSURL *)url completionHandler:(void (^ _Nullable)(BOOL))completion {
    if (completion) {
        completion(NO);
    }
}

- (UIInterfaceOrientationMask)mgl_supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

@end
