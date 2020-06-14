#ifndef MGLSignpost_h
#define MGLSignpost_h

#include <os/log.h>
#include <os/signpost.h>

#define SIGNPOST_CONCAT2(x,y)   x##y
#define SIGNPOST_CONCAT(x,y)    SIGNPOST_CONCAT2(x,y)
#define SIGNPOST_NAME(x)        SIGNPOST_CONCAT(signpost,x)

#define MGL_CREATE_SIGNPOST(log) \
    ({ \
        os_signpost_id_t SIGNPOST_NAME(__LINE__) = OS_SIGNPOST_ID_INVALID; \
        if (log != OS_LOG_DISABLED) { \
            if (__builtin_available(iOS 12.0, macOS 10.14, *)) { \
                SIGNPOST_NAME(__LINE__) = os_signpost_id_generate(log); \
            } \
        } \
        SIGNPOST_NAME(__LINE__); \
    })

#define MGL_SIGNPOST_BEGIN(log, signpost, name, ...) \
    ({ \
        if ((log != OS_LOG_DISABLED) && (signpost != OS_SIGNPOST_ID_INVALID)) { \
            if (__builtin_available(iOS 12.0, macOS 10.14, *)) { \
                os_signpost_interval_begin(log, signpost, name, ##__VA_ARGS__); \
            } \
        } \
    })

#define MGL_SIGNPOST_END(log, signpost, name, ...) \
    ({ \
        if ((log != OS_LOG_DISABLED) && (signpost != OS_SIGNPOST_ID_INVALID)) { \
            if (__builtin_available(iOS 12.0, macOS 10.14, *)) { \
                os_signpost_interval_end(log, signpost, name, ##__VA_ARGS__); \
            } \
        } \
    })

#define MGL_SIGNPOST_EVENT(log, signpost, name, ...) \
    ({ \
        if ((log != OS_LOG_DISABLED) && (signpost != OS_SIGNPOST_ID_INVALID)) { \
            if (__builtin_available(iOS 12.0, macOS 10.14, *)) { \
                os_signpost_event_emit(log, signpost, name, ##__VA_ARGS__); \
            } \
        } \
    })

#endif /* MGLSignpost_h */
