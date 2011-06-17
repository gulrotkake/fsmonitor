#import "fstree.h"

@interface File : NSObject
{
}
@property (copy) NSString *fileName;
@property (retain) NSDictionary *attributes;

- (id) initWithPath:(NSString *)path;
@end

@implementation File
@synthesize fileName, attributes;

- (id) initWithPath:(NSString *)path
{
    self = [super init];
    if (self)
    {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        self.fileName = path;
        self.attributes = [fileManager attributesOfItemAtPath:fileName error:NULL];
    }
    return self;
}

- (void) dealloc
{
    self.fileName = nil;
    self.attributes = nil;
    [super dealloc];
}

@end

@interface FSTree ()
@property (retain) NSMutableDictionary *pathTree;
@property (retain) NSFileManager *fileManager;
@property (assign) id<FileSystemChangesListener> changesListener;
@end

@implementation FSTree
@synthesize pathTree, fileManager, changesListener;
- (NSString *) parsePath:(NSString *)path
{
    if (!path || [path length] == 0) return nil;
    unichar ch = [path characterAtIndex:0];

    // Path is absolute.
    if (ch == '/' || ch == '~') return [path stringByStandardizingPath];

    // Path is relative
    NSString *newPath = [[fileManager currentDirectoryPath] stringByAppendingPathComponent: path];
    return [newPath stringByStandardizingPath];
}

- (void) scanPath:(NSString *)path recursive:(BOOL)recursive
{
    NSError *error;
    NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:path error:&error];
    BOOL isDir;
    NSMutableDictionary *files = [NSMutableDictionary dictionary];
    for (NSString *fileName in directoryContents)
    {
        NSString *absoluteFilename = [path stringByAppendingPathComponent: fileName];
        isDir = NO;
        // Is this a directory
        [fileManager fileExistsAtPath:absoluteFilename isDirectory:&isDir];
        if (isDir && recursive)
        {
            // Add and scan recursively.
            [self scanPath: absoluteFilename recursive:recursive];
        }
        else
        {
            // Just add and monitor.
            File *file = [[[File alloc] initWithPath:fileName] autorelease];
            [files setObject:file forKey:fileName];
        }
    }
    [pathTree setObject:files forKey:path];
}


- (id) initWithPathsAndListener:(NSArray*)paths listener:(id<FileSystemChangesListener>)listener
{
    self = [super init];
    if (self)
    {
        self.changesListener = listener;
        self.fileManager = [NSFileManager defaultManager];
        self.pathTree = [NSMutableDictionary dictionaryWithCapacity:[paths count]];
        for (NSString *path in paths)
        {
            NSString *absolutePath = [self parsePath: path];
            [self scanPath: absolutePath recursive:YES];
        }
    }
    return self;
}

- (void) updatePath:(NSString *)inPath
{
    NSString *path = [inPath stringByStandardizingPath];
    NSMutableDictionary *oldFiles = [pathTree objectForKey: path];
    [self scanPath: path recursive:NO];
    NSDictionary *newFiles = [pathTree objectForKey: path];

    // Compare two and output differences.
    for (NSString *key in newFiles)
    {
        File *a = [newFiles objectForKey: key];
        File *b = [oldFiles objectForKey: key];

        if (!b)
        {
            [self.changesListener fileAdded: key];
        }
        else if (![a.attributes isEqualToDictionary:b.attributes])
        {
            [self.changesListener fileModified: key];
        }
        [oldFiles removeObjectForKey: key];
    }

    for (NSString *key in oldFiles)
    {
        [self.changesListener fileDeleted: key];
    }
}

- (void) dealloc
{
    self.changesListener = nil;
    self.fileManager = nil;
    self.pathTree = nil;
    [super dealloc];
}

@end
