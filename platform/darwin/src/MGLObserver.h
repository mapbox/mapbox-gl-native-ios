#import "MGLMapView+Impl.h"
#import "MGLFoundation.h"

NS_ASSUME_NONNULL_BEGIN


// TODO: DOCS, this might not need to be public
typedef NSString *MGLObserverEvent NS_TYPED_ENUM;
FOUNDATION_EXPORT MGL_EXPORT MGLObserverEvent const MGLObserverEventResourceRequest;

@interface MGLObserver : NSObject
@property (nonatomic) NSUInteger identifier;
- (void)subscribeToObserver:(MGLObserver *)observer forEventType:(NSString *)eventType;
- (void)unsubscribeFromObserver:(MGLObserver *)observer;
@end


@protocol MGLObservable



@end


NS_ASSUME_NONNULL_END
