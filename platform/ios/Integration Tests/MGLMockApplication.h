@import Foundation;
@import UIKit;
#import "../src/MGLApplication_Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface MGLMockApplication : NSObject <MGLApplication>

- (void)enterBackground;
- (void)enterForeground;
- (void)resignActive;
- (void)becomeActive;

@property(nonatomic, readwrite) UIApplicationState applicationState;

@end

NS_ASSUME_NONNULL_END
