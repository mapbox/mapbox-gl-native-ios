#import "MGLMapView+Impl.h"
#import "MGLFoundation.h"

NS_ASSUME_NONNULL_BEGIN


// TODO: DOCS, this might not need to be public
typedef NSString *MGLResourceType NS_TYPED_ENUM;
FOUNDATION_EXPORT MGL_EXPORT MGLResourceType const MGLResourceTypeUnknown;
FOUNDATION_EXPORT MGL_EXPORT MGLResourceType const    MGLResourceTypeStyle;
FOUNDATION_EXPORT MGL_EXPORT MGLResourceType const    MGLResourceTypeSource;
FOUNDATION_EXPORT MGL_EXPORT MGLResourceType const    MGLResourceTypeTile;
FOUNDATION_EXPORT MGL_EXPORT MGLResourceType const    MGLResourceTypeGlyphs;
FOUNDATION_EXPORT MGL_EXPORT MGLResourceType const    MGLResourceTypeSpriteImage;
FOUNDATION_EXPORT MGL_EXPORT MGLResourceType const    MGLResourceTypeSpriteJSON;
FOUNDATION_EXPORT MGL_EXPORT MGLResourceType const    MGLResourceTypeImage;

@interface MGLEventMonitoringRequest : NSObject
@property (nonatomic) NSURL *url;
@property (nonatomic) MGLResourceType resourceType;
@property (nonatomic) NSString *priority; // This can have two values, regular or low. Should make enum?

- (MGLEventMonitoringRequest *)requestWithURL:(NSURL *)url andResourceType:(MGLResourceType)resourceType withPriorityLevel:(NSString *)priorityLevel;
@end

@interface MGLEventMonitoringResponse : NSObject

@end

@interface MGLObserver : NSObject
@property (nonatomic) NSUInteger identifier;
@end


@protocol MGLObservable

- (void)subscribeToObserver:(MGLObserver *)observer forEventType:(NSString *)eventType;
- (void)unsubscribeFromObserver:(MGLObserver *)observer;
//- (MGLEventMonitoringResponse *)getResponseFromMapView:(MGLMapView *)mapView for (MGLEventMonitoringRequest *)request;
@end


NS_ASSUME_NONNULL_END
