#import "MGLApplication_Private.h"

@implementation UIApplication (MGLApplicationConformance)

- (void)mgl_openURL:(NSURL*)url completionHandler:(void (^ __nullable)(BOOL success))completion {
    if (@available(iOS 10.0, *)) {
        [self openURL:url options:@{} completionHandler:completion];
    }
    else {
        BOOL result = [self openURL:url];
        if (completion) {
            completion(result);
        }
    }
}

- (UIInterfaceOrientationMask)mgl_supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window {

    if (window && [self.delegate respondsToSelector:@selector(application:supportedInterfaceOrientationsForWindow:)]) {
        return [self.delegate application:self supportedInterfaceOrientationsForWindow:window];
    }

    // "The system only calls this method if the application delegate has not
    // implemented the delegate equivalent. It returns the orientations specified by
    // the application's info.plist. If no supported interface orientations were
    // specified it will return UIInterfaceOrientationMaskAll on an iPad and
    // UIInterfaceOrientationMaskAllButUpsideDown on a phone.  The return value
    // should be one of the UIInterfaceOrientationMask values which indicates the
    // orientations supported by this application."
    UIInterfaceOrientationMask selfMask = [self supportedInterfaceOrientationsForWindow:window];

#ifdef DEBUG
    // "The system intersects the view controller's supported orientations with
    // the app's supported orientations (as determined by the Info.plist file or
    // the app delegate's application:supportedInterfaceOrientationsForWindow:
    // method) and the device's supported orientations to determine whether to rotate.

    // If no delegate method, check the application's plist.
    static UIInterfaceOrientationMask orientationMask = UIInterfaceOrientationMaskAll;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // No application delegate
        NSArray *orientations = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"UISupportedInterfaceOrientations"];

        // Application's info plist provided supported orientations.
        if (orientations.count > 0) {
            orientationMask = 0;

            NSDictionary *lookup =
            @{
              @"UIInterfaceOrientationPortrait" : @(UIInterfaceOrientationMaskPortrait),
              @"UIInterfaceOrientationPortraitUpsideDown" : @(UIInterfaceOrientationMaskPortraitUpsideDown),
              @"UIInterfaceOrientationLandscapeLeft" : @(UIInterfaceOrientationMaskLandscapeLeft),
              @"UIInterfaceOrientationLandscapeRight" : @(UIInterfaceOrientationMaskLandscapeRight)
              };

            for (NSString *orientation in orientations) {
                UIInterfaceOrientationMask mask = ((NSNumber*)lookup[orientation]).unsignedIntegerValue;
                orientationMask |= mask;
            }
        }
    });

    NSAssert(selfMask == orientationMask, @"Masks should match");
#endif

    return selfMask;
}
@end
