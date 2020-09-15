#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class MGLMapView;

NS_ASSUME_NONNULL_BEGIN

@protocol MGLApplication <NSObject>
@property(nonatomic, readonly) UIApplicationState applicationState;
@property(nonatomic, readonly) UIInterfaceOrientation statusBarOrientation __TVOS_PROHIBITED;

- (void)mgl_openURL:(NSURL*)url completionHandler:(void (^ __nullable)(BOOL success))completion;
- (UIInterfaceOrientationMask)mgl_supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window;
@end

@interface UIApplication (MGLApplicationConformance) <MGLApplication>
@end

NS_ASSUME_NONNULL_END

