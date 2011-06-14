#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>
#import "fstree.h"

#include <getopt.h>

void iFSEventStreamCallback(
    ConstFSEventStreamRef streamRef,
    void *clientCallBackInfo,
    size_t numEvents,
    void *eventPaths,
    const FSEventStreamEventFlags eventFlags[],
    const FSEventStreamEventId eventIds[]
) {
    const char *const *paths = (const char *const *)eventPaths;
    FSTree *tree = (FSTree*)clientCallBackInfo;
    for (unsigned i = 0; i<numEvents; ++i) {
        NSString *path = [NSString stringWithUTF8String:paths[i]];
        [tree updatePath: path];
    }
}

int run(NSArray *paths) {
    FSTree *tree = [[[FSTree alloc] initWithPaths:paths] autorelease];
    FSEventStreamContext context = {
        0,
        tree,
        (CFAllocatorRetainCallBack)CFRetain,
        (CFAllocatorReleaseCallBack)CFRelease,
        (CFAllocatorCopyDescriptionCallBack)CFCopyDescription
    };

    FSEventStreamRef ref = FSEventStreamCreate(
        kCFAllocatorDefault,
        iFSEventStreamCallback,
        &context,
        (CFArrayRef)paths,
        kFSEventStreamEventIdSinceNow,
        .1,
        kFSEventStreamCreateFlagNoDefer
    );

    FSEventStreamScheduleWithRunLoop(
        ref,
        CFRunLoopGetCurrent(),
        kCFRunLoopDefaultMode
    );

    FSEventStreamStart(ref);

    CFRunLoopRun();

    FSEventStreamStop(ref);
    FSEventStreamInvalidate(ref);
    FSEventStreamRelease(ref);
    return EXIT_SUCCESS;
}

int main(int argc, char *const *argv) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSMutableArray *execs = [NSMutableArray array];
    static struct option longOpts[] = {
        { "exec", required_argument, NULL, 'e' },
        { NULL, 0, NULL, 0 }
    };

    const char *optString = "e:h?";
    int longIndex;
    int res;
    int status = -1;
    do {
        res = getopt_long_only(argc, argv, optString, longOpts, &longIndex);
        switch(res) {
        case 'e':
            if (status == -1) status = 1;
            [execs addObject:[NSString stringWithUTF8String:optarg]];
            break;
        case 'h':
        case '?':
            status = 0;
            break;
        case 0: // long arg
        case -1:
        default:
            break;
        }
    } while(res != -1);

    // Paths to scan
    NSMutableArray *paths = [NSMutableArray array];
    char *const *rav = argv + optind;
    int rac = argc-optind;
    for (int i = 0; i<rac; ++i) {
        [paths addObject: [NSString stringWithUTF8String:rav[i]]];
    }

    if (![paths count]) {
        [paths addObject:@"."];
    }

    int ret = status? run(paths) : 1;

    [pool drain];
    return ret;
}
