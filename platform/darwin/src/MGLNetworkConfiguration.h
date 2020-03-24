#import <Foundation/Foundation.h>

#import "MGLFoundation.h"

NS_ASSUME_NONNULL_BEGIN

@class MGLNetworkConfiguration;

/**
 :nodoc:
 The `MGLNetworkConfigurationSessionDelegate` protocol provides an `NSURLSession`
 object for the `MGLNetworkConfiguration`. This API should be considered
 experimental, likely to be removed or changed in future releases.
 */
@protocol MGLNetworkConfigurationSessionDelegate <NSObject>
- (NSURLSession *)sessionForNetworkConfiguration:(MGLNetworkConfiguration *)configuration;
@end


/**
 The `MGLNetworkConfiguration` object provides a global way to set a base
 `NSURLSessionConfiguration`, and other resources.
 */
MGL_EXPORT
@interface MGLNetworkConfiguration : NSObject

/**
 :nodoc:
 Delegate for the `MGLNetworkConfiguration` class.
 */
@property (nonatomic, weak) id delegate;

/**
 Returns the shared instance of the `MGLNetworkConfiguration` class.
 */
@property (class, nonatomic, readonly) MGLNetworkConfiguration *sharedManager;

/**
 The session configuration object that is used by the `NSURLSession` objects
 in this SDK.
 
 If this property is set to nil or if no session configuration is provided this property
 is set to the default session configuration.
 
 Assign this object before instantiating any `MGLMapView` object.
 
 @note: `NSURLSession` objects store a copy of this configuration. Any further changes
 to mutable properties on this configuration object passed to a session’s initializer
 will not affect the behavior of that session.
 
 */
@property (atomic, strong, null_resettable) NSURLSessionConfiguration *sessionConfiguration;

@end

NS_ASSUME_NONNULL_END
