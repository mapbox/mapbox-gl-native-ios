#import "MGLFoundation.h"
#import "MGLEvent.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark -

/**
 Base class for observers used to receive notifications from a type conforming to
 the `MGLObservable` protocol.
 Subclasses should only override `-[MGLObserver notifyWithEvent:]`.
 */
MGL_EXPORT
@interface MGLObserver: NSObject

/// A unique identifier that can be used to identify an observer.
@property (nonatomic, readonly) NSUInteger identifier;

/// Primary notification method.
- (void)notifyWithEvent:(MGLEvent*)event;

// TODO: document
- (BOOL)isEqualToObserver:(MGLObserver *)other;
@end


#pragma mark -

/**
 The `MGLObservable` protocol declares methods that conforming classes should
 implement should they want to observe low-level events of type `MGLEvent`.
 Currently only `MGLMapView` implements `MGLObservable`.
 */
MGL_EXPORT
@protocol MGLObservable

/**
 Subscribes an `MGLObserver` to a provided set of event types.
 `MGLObservable` will hold a strong reference to an `MGLObserver` instance,
 therefore, in order to stop receiving notifications (and to avoid memory leaks),
 the caller must call unsubscribe with the `MGLObserver` instance used for
 the initial subscription.
 
 @param observer an MGLObserver
 @param events a set of event types to subscribe to.
 */
- (void)subscribeForObserver:(nonnull MGLObserver *)observer
                      events:(nonnull NSSet<MGLEventType> *)events;

/**
 Unsubscribes an `MGLObserver` from a provided set of event types.
 
 @param observer an MGLObserver
 @param events a set of event types to unsubscribe from.
 */
- (void)unsubscribeForObserver:(nonnull MGLObserver *)observer
                        events:(nonnull NSSet<MGLEventType> *)events;
/**
 Unsubscribes an `MGLObserver` from all events (and release the strong reference).
 
 @param observer an MGLObserver
 */
- (void)unsubscribeForObserver:(nonnull MGLObserver *)observer;

@end

NS_ASSUME_NONNULL_END
