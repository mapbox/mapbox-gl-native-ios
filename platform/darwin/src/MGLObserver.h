//#import "MGLMapView+Impl.h"
#import "MGLFoundation.h"
#import "MGLEvent.h"

NS_ASSUME_NONNULL_BEGIN






MGL_EXPORT
@interface MGLObserver: NSObject
- (void)notifyWithEvent:(MGLEvent*)event;
@property (nonatomic, readonly) NSUInteger identifier;
- (BOOL)isEqualToObserver:(MGLObserver *)other;
@end


MGL_EXPORT
@protocol MGLObservable
/**
 * @brief Subscribes an \sa Observer to a provided list of event types.
 * Observable will hold a strong reference to an \sa Observer instance, therefore,
 * in order to stop receiving notifications, caller must call unsubscribe with an
 * \sa Observer instance used for an initial subscription.
 *
 * @param observer an \sa Observer
 * @param events an array of event types to be subscribed to.
 */
- (void)subscribeForObserver:(nonnull MGLObserver *)observer
                      events:(nonnull NSSet<MGLEventType> *)events;
/**
 * @brief Unsubscribes an \sa Observer from a provided list of event types.
 *
 * @param observer an \sa Observer
 * @param events an array of event types to be unsubscribed from.
 */
- (void)unsubscribeForObserver:(nonnull MGLObserver *)observer
                        events:(nonnull NSSet<MGLEventType> *)events;
/**
 * @brief Unsubscribes an \sa Observer from all events.
 *
 * @param observer an \sa Observer
 */
- (void)unsubscribeForObserver:(nonnull MGLObserver *)observer;

@end




//
////@interface MGLObserver : NSObject
////@property (nonatomic) NSUInteger identifier;
////- (void)subscribeToObserver:(MGLObserver *)observer forEventType:(NSString *)eventType;
////- (void)unsubscribeFromObserver:(MGLObserver *)observer;
////@end
//
//
//@protocol MGLObservable
//
//
//
//@end


NS_ASSUME_NONNULL_END
