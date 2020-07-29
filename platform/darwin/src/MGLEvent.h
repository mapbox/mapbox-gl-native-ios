#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MGLEvent: NSObject
@property (nonatomic, readonly, copy) NSString *type;
@property (nonatomic, readonly) NSTimeInterval begin;
@property (nonatomic, readonly) NSTimeInterval end;
@property (nonatomic, readonly, copy) id data;

- (BOOL)isEqualToEvent:(MGLEvent *)otherEvent;
@end

NS_ASSUME_NONNULL_END
