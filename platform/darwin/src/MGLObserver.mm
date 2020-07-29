
#import "MGLObserver_Private.h"
#import "MGLLoggingConfiguration_Private.h"
#import "MGLEvent_Private.h"

// TODO: Should there be separate bindings for each observer (map, file source, etc)?


namespace mbgl {
namespace darwin {
void Observer::notify(const ObservableEvent& event) {
    
    if (!observer) {
        MGLLogWarning(@"Platform observer has been deallocated");
        return;
    }
    
    MGLEvent *eventThing = [[MGLEvent alloc] initWithEvent:event];
    [observer notifyWithEvent:eventThing];
}

std::size_t Observer::id() const {
    if (!observer) {
        MGLLogWarning(@"Platform observer has been deallocated");
        return 0;
    }
    
    return static_cast<std::size_t>(observer.identifier);
}
}
}


@implementation MGLObserver
//@synthesize peer = _peer;

+ (NSUInteger)nextIdentifier {
    static NSUInteger identifier;
    return ++identifier;
}

- (void)dealloc {
    NSLog(@"Observer dealloc");
}

- (instancetype)init {
    self = [super init];
    
    if (!self) return nil;
    
    auto peer = std::make_shared<mbgl::darwin::Observer>(self);
    
    _identifier = [MGLObserver nextIdentifier];
    _peer = peer;
    
    return self;
}

- (void)notifyWithEvent:(MGLEvent*)event {
    // Do nothing
    NSLog(@"Hello event: %@", event);
}

- (BOOL)isEqualToObserver:(MGLObserver *)other {
    if (self == other)
        return YES;

    if (self.identifier != other.identifier)
        return NO;
    
    return (self.peer == other.peer);
}

- (BOOL)isEqual:(id)other {
    if (self == other)
        return YES;

    if (![other isKindOfClass:[MGLObserver class]]) {
        return NO;
    }
    
    return [self isEqualToObserver:(MGLObserver*)other];
}

- (NSUInteger)hash {
    NSUInteger peerHash = reinterpret_cast<NSUInteger>(self.peer.get());
    
    NSUInteger width = (sizeof(NSUInteger) * __CHAR_BIT__);
    NSUInteger shift = self.identifier % width;
    
    NSUInteger newHash = (peerHash << shift) | (peerHash >> (width - shift));
    return newHash;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; identifier = %lu, peer = %p, hash = %lu>",
            NSStringFromClass([self class]), (void *)self,
            (unsigned long)self.identifier,
            self.peer.get(),
            [self hash]];
}

 
@end
