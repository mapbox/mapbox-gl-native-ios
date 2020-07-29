#import <mbgl/util/observable.hpp>

#import "MGLObserver.h"

NS_ASSUME_NONNULL_BEGIN

namespace mbgl {
namespace darwin {

class Observer : public mbgl::Observer {
public:
    Observer(MGLObserver *observer_): observer(observer_) {}
    virtual ~Observer() = default;
    virtual void notify(const ObservableEvent& event);
    virtual std::size_t id() const;

protected:

    /// Cocoa map view that this adapter bridges to.
    __weak MGLObserver *observer = nullptr;
};
}
}


@interface MGLObserver ()
@property (nonatomic, assign) std::shared_ptr<mbgl::darwin::Observer> peer;
@end

NS_ASSUME_NONNULL_END

