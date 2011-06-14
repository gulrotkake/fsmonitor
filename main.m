#import <CoreServices/CoreServices.h>
#import <Foundation/Foundation.h>
#import "fstree.h"

/* Goal
   Changes:
   <action> <filename>
   Example:
   M foo.c
   A bar.c
   D baz.c
*/

/*
 kFSEventStreamEventFlagNone = 0x00000000,
 kFSEventStreamEventFlagMustScanSubDirs = 0x00000001,
 kFSEventStreamEventFlagUserDropped = 0x00000002,
 kFSEventStreamEventFlagKernelDropped = 0x00000004,
 kFSEventStreamEventFlagEventIdsWrapped = 0x00000008,
 kFSEventStreamEventFlagHistoryDone = 0x00000010,
 kFSEventStreamEventFlagRootChanged = 0x00000020,
 kFSEventStreamEventFlagMount = 0x00000040,
 kFSEventStreamEventFlagUnmount = 0x00000080
*/

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

int main(int argc, const char **argv) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSMutableArray *paths = [[[[NSProcessInfo processInfo] arguments] mutableCopyWithZone: nil] autorelease];

    [paths removeObjectAtIndex:0];

    if (![paths count]) {
        [paths addObject:@"."];
    }

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

    [pool drain];
	return EXIT_SUCCESS;
}
