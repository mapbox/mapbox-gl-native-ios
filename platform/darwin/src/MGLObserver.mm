
#import <mbgl/util/observable.hpp>

#import "MGLObserver.h"

// TODO: Should there be separate bindings for each observer (map, file source, etc)?

/*
 TODO: This is an enum for when additional event types are added.
 */
const MGLObserverEventType MGLObserverEventTypeResourceRequest = @"resource-request";

@implementation MGLObserverEvent

@end

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

- (void)subscribeToObserver:(MGLObserver *)observer forEventType:(MGLObserverEventType)eventType
{

//    auto *cEventType = [eventType cStringUsingEncoding:NSUTF8StringEncoding];
    // TODO: Reference to type 'const std::vector<std::string>' (aka 'const vector<basic_string<char, char_traits<char>, allocator<char> > >') could not bind to an lvalue of type 'const char '
//    _mbglObservable->subscribe(_mbglObserver, cEventType);
}

- (void)unsubscribeFromObserver:(MGLObserver *)observer
{

}

@end
