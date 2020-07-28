
#import <mbgl/util/observable.hpp>

#import "MGLObserver.h"

// TODO: Should there be separate bindings for each observer (map, file source, etc)?
const MGLObserverEvent MGLObserverEventResourceRequest = @"resource-request";

@interface MGLObserver()
@property (nonatomic) std::shared_ptr<mbgl::Observable> mbglObservable;
@property (nonatomic) std::shared_ptr<mbgl::Observer> mbglObserver;
@end

@implementation MGLObserver

- (instancetype)initWithObservable:(std::shared_ptr<mbgl::Observer>)observer
{
    self = [super init];
    if (self) {
        _mbglObserver = observer;
    }
    return self;
}

- (void)subscribeToObserver:(MGLObserver *)observer forEventType:(MGLObserverEvent)eventType
{

    auto *cEventType = [eventType cStringUsingEncoding:NSUTF8StringEncoding];
    _mbglObservable->subscribe(_mbglObserver, eventType);
}

- (void)unsubscribeFromObserver:(MGLObserver *)observer
{

}

@end
