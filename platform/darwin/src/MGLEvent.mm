#import "MGLEvent_Private.h"

// From value.md
id MGLJSONObjectFromMapboxBaseValue(const mapbox::base::Value &value) {
    // Supported types are `int`, `uint`, `bool`, `double`, `array`, `object` and `string`.
    return value.match(
                       [](const mapbox::base::NullValue) -> id { return [NSNull null]; },
                       [](const std::string &value)            { return @(value.c_str()); },
                       [](bool value)                          { return @(value); },
                       [](uint64_t value)                      { return @(value); },
                       [](int64_t value)                       { return @(value); },
                       [](double value)                        { return @(value); },
                       [](const mapbox::base::ValueArray& valueArray) {
                            NSMutableArray *array = [NSMutableArray arrayWithCapacity:valueArray.size()];
                            for (const auto& v : valueArray) {
                                [array addObject:MGLJSONObjectFromMapboxBaseValue(v)];
                            }
                            return array;
                       },
                       [](const mapbox::base::ValueObject& object) {
                            NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:object.size()];
                            for (const auto& kv : object) {
                                dictionary[@(kv.first.c_str())] = MGLJSONObjectFromMapboxBaseValue(kv.second);
                            }
                            return dictionary;
                       }
                       );
}

@implementation MGLEvent

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithEvent:(const mbgl::ObservableEvent&)event {
    
    self = [super init];

    if (!self)
        return nil;

    auto systemClockNow = std::chrono::system_clock::now();
    auto steadyClockNow = std::chrono::steady_clock::now();
    auto begin = std::chrono::time_point_cast<std::chrono::system_clock::duration>(systemClockNow +
                                                                                   (event.begin - steadyClockNow));
    auto end = std::chrono::time_point_cast<std::chrono::system_clock::duration>(systemClockNow +
                                                                                 (event.end - steadyClockNow));
    
    auto beginTime  = std::chrono::duration<double, std::ratio<1>>(begin.time_since_epoch()).count();
    auto endTime    = std::chrono::duration<double, std::ratio<1>>(end.time_since_epoch()).count();

    _type   = [NSString stringWithUTF8String:event.type.c_str()];
    _begin  = beginTime;
    _end    = endTime;
//    _begin = [NSDate dateWithTimeIntervalSince1970:beginTime];
//    _end   = [NSDate dateWithTimeIntervalSince1970:endTime];
    _data  = MGLJSONObjectFromMapboxBaseValue(event.data);
    
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p; type = %@, begin = %f, end = %f, data = %@>",
            NSStringFromClass([self class]), (void *)self,
            self.type,
            self.begin,
            self.end,
            self.data];
}

- (NSUInteger)hash {
    return self.type.hash ^ @(self.begin).hash ^ @(self.end).hash;
}

- (BOOL)isEqualToEvent:(MGLEvent *)other {
    if (self == other)
        return YES;

    // Ignore the value at this moment.
    return ((self.type == other.type) &&
            (self.begin == other.begin) &&
            (self.end == other.end));
}

- (BOOL)isEqual:(id)other {
    if (self == other)
        return YES;

    if (![other isKindOfClass:[MGLEvent class]]) {
        return NO;
    }
    
    return [self isEqualToEvent:(MGLEvent*)other];
}

@end
