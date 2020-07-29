#import "MGLFoundation.h"

NS_ASSUME_NONNULL_BEGIN

//// TODO: DOCS, this might not need to be public
typedef NSString *MGLEventType NS_TYPED_EXTENSIBLE_ENUM;
FOUNDATION_EXPORT MGL_EXPORT MGLEventType const MGLEventTypeResourceRequest;


@interface MGLEvent: NSObject
@property (nonatomic, readonly, copy) MGLEventType type;
@property (nonatomic, readonly) NSTimeInterval begin;
@property (nonatomic, readonly) NSTimeInterval end;
@property (nonatomic, readonly, copy) id data;

- (BOOL)isEqualToEvent:(MGLEvent *)otherEvent;
@end

NS_ASSUME_NONNULL_END
