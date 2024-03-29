#import "MGLOfflinePack_Private.h"

#import "MGLOfflineStorage_Private.h"
#import "MGLOfflineRegion_Private.h"
#import "MGLTilePyramidOfflineRegion.h"
#import "MGLTilePyramidOfflineRegion_Private.h"
#import "MGLShapeOfflineRegion.h"
#import "MGLShapeOfflineRegion_Private.h"
#import "MGLLoggingConfiguration_Private.h"

#import "NSValue+MGLAdditions.h"

#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR
    #import "MGLMapboxEvents.h"
#endif

#include <mbgl/map/map_options.hpp>
#include <mbgl/storage/database_file_source.hpp>

const MGLExceptionName MGLInvalidOfflinePackException = @"MGLInvalidOfflinePackException";

/**
 Assert that the current offline pack is valid.

 This macro should be used at the beginning of any public-facing instance method
 of `MGLOfflinePack`. For private methods, an assertion is more appropriate.
 */
#define MGLAssertOfflinePackIsValid() \
    do { \
        if (_state == MGLOfflinePackStateInvalid) { \
            [NSException raise:MGLInvalidOfflinePackException \
                        format: \
             @"-[MGLOfflineStorage removePack:withCompletionHandler:] has been called " \
             @"on this instance of MGLOfflinePack, rendering it invalid. It is an " \
             @"error to send any message to this pack."]; \
        } \
    } while (NO);

@interface MGLTilePyramidOfflineRegion () <MGLOfflineRegion_Private, MGLTilePyramidOfflineRegion_Private>
@end

@interface MGLShapeOfflineRegion () <MGLOfflineRegion_Private, MGLShapeOfflineRegion_Private>
@end

class MBGLOfflineDownloadObserver : public mbgl::OfflineDownloadObserver {
public:
    MBGLOfflineDownloadObserver(MGLOfflinePack *pack_) : pack(pack_) {}

    void statusChanged(const mbgl::OfflineDownloadStatus &status) override;
    void responseError(mbgl::Response::Error error) override;
    void mapboxTileCountLimitExceeded(uint64_t limit) override;
    
private:
    __weak MGLOfflinePack *pack = nullptr;
};

@interface MGLOfflinePack ()

@property (nonatomic, nullable, readwrite) mbgl::OfflineRegion *mbglOfflineRegion;
@property (nonatomic, readwrite) MGLOfflinePackProgress progress;

@end

@implementation MGLOfflinePack {
    BOOL _isSuspending;
    std::shared_ptr<mbgl::DatabaseFileSource> _mbglDatabaseFileSource;
}

- (instancetype)init {
    MGLLogInfo(@"Calling this initializer is not allowed.");
    if (self = [super init]) {
        _state = MGLOfflinePackStateInvalid;
        NSLog(@"%s called; did you mean to call +[MGLOfflineStorage addPackForRegion:withContext:completionHandler:] instead?", __PRETTY_FUNCTION__);
    }
    return self;
}

- (instancetype)initWithMBGLRegion:(mbgl::OfflineRegion *)region {
    if (self = [super init]) {
        _mbglOfflineRegion = region;
        _state = MGLOfflinePackStateUnknown;

        _mbglDatabaseFileSource = [[MGLOfflineStorage sharedOfflineStorage] mbglDatabaseFileSource];
        _mbglDatabaseFileSource->setOfflineRegionObserver(*_mbglOfflineRegion, std::make_unique<MBGLOfflineDownloadObserver>(self));
    }
    return self;
}

- (void)dealloc {
    MGLAssert(_state == MGLOfflinePackStateInvalid, @"MGLOfflinePack was not invalided prior to deallocation.");
}

- (id <MGLOfflineRegion>)region {
    MGLAssertOfflinePackIsValid();

    const mbgl::OfflineDownloadParameters &downloadParameters = _mbglOfflineRegion->getDefinition();
    MGLAssert([MGLTilePyramidOfflineRegion conformsToProtocol:@protocol(MGLOfflineRegion_Private)], @"MGLTilePyramidOfflineRegion should conform to MGLOfflineRegion_Private.");
    MGLAssert([MGLShapeOfflineRegion conformsToProtocol:@protocol(MGLOfflineRegion_Private)], @"MGLShapeOfflineRegion should conform to MGLOfflineRegion_Private.");
    
    id<MGLOfflineRegion> region = downloadParameters.isGeometryDefined() ?
        [[MGLShapeOfflineRegion alloc] initWithOfflineDownloadParameters:downloadParameters] :
        [[MGLTilePyramidOfflineRegion alloc] initWithOfflineDownloadParameters:downloadParameters];
    return region;
    
}

- (NSData *)context {
    MGLAssertOfflinePackIsValid();

    const mbgl::OfflineRegionMetadata &metadata = _mbglOfflineRegion->getMetadata();
    return [NSData dataWithBytes:&metadata[0] length:metadata.size()];
}

- (void)setContext:(NSData *)context completionHandler:(void (^_Nullable)(NSError * _Nullable error))completion {
    MGLAssertOfflinePackIsValid();
    
    mbgl::OfflineRegionMetadata metadata(context.length);
    [context getBytes:&metadata[0] length:metadata.size()];
    
    [self willChangeValueForKey:@"context"];
    __weak MGLOfflinePack *weakSelf = self;
    _mbglDatabaseFileSource->updateOfflineMetadata(_mbglOfflineRegion->getID(), metadata, [&, completion, weakSelf](mbgl::expected<mbgl::OfflineRegionMetadata, std::exception_ptr> mbglOfflineRegionMetadata) {
        NSError *error;
        if (!mbglOfflineRegionMetadata) {
            NSString *errorDescription = @(mbgl::util::toString(mbglOfflineRegionMetadata.error()).c_str());
            error = [NSError errorWithDomain:MGLErrorDomain code:MGLErrorCodeModifyingOfflineStorageFailed userInfo:errorDescription ? @{
                NSLocalizedDescriptionKey: errorDescription,
            } : nil];
#if TARGET_OS_IPHONE || TARGET_OS_SIMULATOR
            [[MMEEventsManager sharedManager] reportError:error];
#endif
        }
        dispatch_async(dispatch_get_main_queue(), [&, completion, weakSelf, error](void) {
            [weakSelf reloadWithCompletionHandler:^(NSError * _Nullable reloadingError) {
                MGLOfflinePack *strongSelf = weakSelf;
                [strongSelf didChangeValueForKey:@"context"];
                if (completion) {
                    completion(error ?: reloadingError);
                }
            }];
        });
    });
}

- (void)reloadWithCompletionHandler:(void (^)(NSError * _Nullable error))completion {
    auto regionID = _mbglOfflineRegion->getID();
    MGLOfflineStorage *sharedOfflineStorage = [MGLOfflineStorage sharedOfflineStorage];
    __weak MGLOfflinePack *weakSelf = self;
    [sharedOfflineStorage getPacksWithCompletionHandler:^(NSArray<MGLOfflinePack *> *packs, __unused NSError * _Nullable error) {
        MGLOfflinePack *strongSelf = weakSelf;
        for (MGLOfflinePack *pack in packs) {
            if (pack.mbglOfflineRegion->getID() == regionID) {
                if (strongSelf.mbglOfflineRegion) {
                    strongSelf->_mbglDatabaseFileSource->setOfflineRegionObserver(*strongSelf.mbglOfflineRegion, nullptr);
                }
                strongSelf.mbglOfflineRegion = pack.mbglOfflineRegion;
                strongSelf->_mbglDatabaseFileSource->setOfflineRegionObserver(*strongSelf.mbglOfflineRegion, std::make_unique<MBGLOfflineDownloadObserver>(strongSelf));
            }
            [pack invalidate];
        }
        completion(error);
    }];
}

- (void)resume {
    MGLLogInfo(@"Resuming pack download.");
    MGLAssertOfflinePackIsValid();

    self.state = MGLOfflinePackStateActive;

    _mbglDatabaseFileSource->setOfflineRegionDownloadState(*_mbglOfflineRegion, mbgl::OfflineRegionDownloadState::Active);
}

- (void)suspend {
    MGLLogInfo(@"Suspending pack download.");
    MGLAssertOfflinePackIsValid();

    if (self.state == MGLOfflinePackStateActive) {
        self.state = MGLOfflinePackStateInactive;
        _isSuspending = YES;
    }

    _mbglDatabaseFileSource->setOfflineRegionDownloadState(*_mbglOfflineRegion, mbgl::OfflineRegionDownloadState::Inactive);
}

- (void)invalidate {
    MGLLogInfo(@"Invalidating pack.");
    MGLAssert(_state != MGLOfflinePackStateInvalid, @"Cannot invalidate an already invalid offline pack.");
    MGLAssert(self.mbglOfflineRegion, @"Should have a valid region");

    @synchronized (self) {
        self.state = MGLOfflinePackStateInvalid;
        if (self.mbglOfflineRegion) {
            _mbglDatabaseFileSource->setOfflineRegionObserver(*self.mbglOfflineRegion, nullptr);
        }
        self.mbglOfflineRegion = nil;
    }
}

- (void)setState:(MGLOfflinePackState)state {
    MGLLogDebug(@"Setting state: %ld", (long)state);
    if (!self.mbglOfflineRegion) {
        // A progress update has arrived after the call to
        // -[MGLOfflineStorage removePack:withCompletionHandler:] but before the
        // removal is complete and the completion handler is called.
        MGLAssert(_state == MGLOfflinePackStateInvalid, @"A valid MGLOfflinePack has no mbgl::OfflineRegion.");
        return;
    }

    MGLAssert(_state != MGLOfflinePackStateInvalid, @"Cannot change the state of an invalid offline pack.");

    if (!_isSuspending || state != MGLOfflinePackStateActive) {
        _isSuspending = NO;
        _state = state;
    }
}

- (void)requestProgress {
    MGLLogInfo(@"Requesting pack progress.");
    MGLAssertOfflinePackIsValid();

    __weak MGLOfflinePack *weakSelf = self;
    _mbglDatabaseFileSource->getOfflineRegionStatus(*_mbglOfflineRegion, [&, weakSelf](mbgl::expected<mbgl::OfflineDownloadStatus, std::exception_ptr> status) {
        if (status) {
            mbgl::OfflineDownloadStatus checkedStatus = *status;
            dispatch_async(dispatch_get_main_queue(), ^{
                MGLOfflinePack *strongSelf = weakSelf;
                [strongSelf OfflineDownloadStatusDidChange:checkedStatus];
            });
        }
    });
}

- (void)OfflineDownloadStatusDidChange:(mbgl::OfflineDownloadStatus)status {
    MGLAssert(_state != MGLOfflinePackStateInvalid, @"Cannot change update progress of an invalid offline pack.");

    switch (status.downloadState) {
        case mbgl::OfflineRegionDownloadState::Inactive:
            self.state = status.complete() ? MGLOfflinePackStateComplete : MGLOfflinePackStateInactive;
            break;

        case mbgl::OfflineRegionDownloadState::Active:
            self.state = MGLOfflinePackStateActive;
            break;
    }

    if (_isSuspending) {
        return;
    }

    MGLOfflinePackProgress progress;
    progress.countOfResourcesCompleted = status.completedResourceCount;
    progress.countOfBytesCompleted = status.completedResourceSize;
    progress.countOfTilesCompleted = status.completedTileCount;
    progress.countOfTileBytesCompleted = status.completedTileSize;
    progress.countOfResourcesExpected = status.requiredResourceCount;
    progress.maximumResourcesExpected = status.requiredResourceCountIsPrecise ? status.requiredResourceCount : UINT64_MAX;
    self.progress = progress;

    NSDictionary *userInfo = @{MGLOfflinePackUserInfoKeyState: @(self.state),
                               MGLOfflinePackUserInfoKeyProgress: [NSValue valueWithMGLOfflinePackProgress:progress]};

    NSNotificationCenter *noteCenter = [NSNotificationCenter defaultCenter];
    [noteCenter postNotificationName:MGLOfflinePackProgressChangedNotification
                              object:self
                            userInfo:userInfo];
}

- (void)didReceiveError:(NSError *)error {
    MGLLogError(@"Error: %@", error.localizedDescription);
    MGLLogInfo(@"Notifying about pack error.");
    
    NSDictionary *userInfo = @{ MGLOfflinePackUserInfoKeyError: error };
    NSNotificationCenter *noteCenter = [NSNotificationCenter defaultCenter];
    [noteCenter postNotificationName:MGLOfflinePackErrorNotification
                              object:self
                            userInfo:userInfo];
}

- (void)didReceiveMaximumAllowedMapboxTiles:(uint64_t)limit {
    MGLLogInfo(@"Notifying reached maximum allowed Mapbox tiles: %lu", (unsigned long)limit);
    NSDictionary *userInfo = @{ MGLOfflinePackUserInfoKeyMaximumCount: @(limit) };
    NSNotificationCenter *noteCenter = [NSNotificationCenter defaultCenter];
    [noteCenter postNotificationName:MGLOfflinePackMaximumMapboxTilesReachedNotification
                              object:self
                            userInfo:userInfo];
}

NSError *MGLErrorFromResponseError(mbgl::Response::Error error) {
    NSInteger errorCode = MGLErrorCodeUnknown;
    switch (error.reason) {
        case mbgl::Response::Error::Reason::NotFound:
            errorCode = MGLErrorCodeNotFound;
            break;

        case mbgl::Response::Error::Reason::Server:
            errorCode = MGLErrorCodeBadServerResponse;
            break;

        case mbgl::Response::Error::Reason::Connection:
            errorCode = MGLErrorCodeConnectionFailed;
            break;

        default:
            break;
    }
    return [NSError errorWithDomain:MGLErrorDomain code:errorCode userInfo:@{
        NSLocalizedFailureReasonErrorKey: @(error.message.c_str())
    }];
}

@end

void MBGLOfflineDownloadObserver::statusChanged(const mbgl::OfflineDownloadStatus &status) {
    __weak MGLOfflinePack *weakPack = pack;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakPack OfflineDownloadStatusDidChange:status];
    });
}

void MBGLOfflineDownloadObserver::responseError(mbgl::Response::Error error) {
    __weak MGLOfflinePack *weakPack = pack;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakPack didReceiveError:MGLErrorFromResponseError(error)];
    });
}

void MBGLOfflineDownloadObserver::mapboxTileCountLimitExceeded(uint64_t limit) {
    __weak MGLOfflinePack *weakPack = pack;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakPack didReceiveMaximumAllowedMapboxTiles:limit];
    });
}
