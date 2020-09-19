#import <Foundation/Foundation.h>
#include <sys/sysctl.h>

NSString* getSysInfoByName(char *typeSpecifier)
{
    size_t size;
    sysctlbyname(typeSpecifier, NULL, &size, NULL, 0);

    char *answer = malloc(size);
    sysctlbyname(typeSpecifier, answer, &size, NULL, 0);

    NSString *results = @(answer);

    free(answer);
    return results;
}
