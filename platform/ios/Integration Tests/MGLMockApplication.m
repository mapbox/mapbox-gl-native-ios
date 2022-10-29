#import "MGLMockApplication.h"

#define TRACE() NSLog(@"%s", __PRETTY_FUNCTION__)

@implementation MGLMockApplication

- (void)dealloc {
    TRACE();
}

- (UIApplicationState)applicationState {
    return _applicationState;
}

- (instancetype)init {
    if ((self = [super init])) {
        _applicationState = UIApplicationStateActive;
    }
    return self;
}

- (void)resignActive {
    TRACE();
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillResignActiveNotification object:self];
    self.applicationState = UIApplicationStateInactive;
}

- (void)enterBackground {
    TRACE();
    [self resignActive];

    self.applicationState = UIApplicationStateBackground;
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidEnterBackgroundNotification object:self];
}

- (void)enterForeground {
    TRACE();
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationWillEnterForegroundNotification object:self];
    self.applicationState = UIApplicationStateInactive;

    [self becomeActive];
}

- (void)becomeActive {
    TRACE();
    self.applicationState = UIApplicationStateActive;
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidBecomeActiveNotification object:self];
}

#pragma mark - MGLApplication

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
