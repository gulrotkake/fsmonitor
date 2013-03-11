#import "fstree.h"

@interface File : NSObject
{
    NSString *fileName;
    NSDictionary *attributes;
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
@synthesize pathTree, fileManager, changesListener, scanRecursively;

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

- (void) updateFile:(NSString *)path files:(NSMutableDictionary *)files
{
    // Add and monitor.
    File *file = [[[File alloc] initWithPath:path] autorelease];
    [files setObject:file forKey:path];
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
            [self scanPath: absoluteFilename recursive:recursive];
        }

        [self updateFile:absoluteFilename files:files];
    }
    [pathTree setObject:files forKey:path];
}


- (id) initWithListener:(id<FileSystemChangesListener>)listener
{
    self = [super init];
    if (self)
    {
        self.changesListener = listener;
        self.fileManager = [NSFileManager defaultManager];
        self.pathTree = [NSMutableDictionary dictionary];
        self.scanRecursively = NO;
    }
    return self;
}

- (void) addPath:(NSString*)path
{
    NSString *absolutePath = [self parsePath: path];
    [self scanPath: absolutePath recursive:scanRecursively];
}

- (NSArray *) paths
{
    return [self.pathTree allKeys];
}

- (void) updateParent:(NSString *)path
{
    NSString *currentPath = path;
    NSString *parent = [path stringByDeletingLastPathComponent];
    while([parent length] > 1)
    {
        NSMutableDictionary *files = [pathTree objectForKey: parent];
        if (files)
        {
            [self.changesListener fileModified:currentPath];
            [self updateFile:currentPath files:files];
        }
        currentPath = parent;
        parent = [parent stringByDeletingLastPathComponent];
    }
}

- (void) updatePath:(NSString *)inPath
{
    NSString *path = [inPath stringByStandardizingPath];
    NSMutableDictionary *oldFiles = [pathTree objectForKey: path];

    // If we are not running recursively update the watched parent as modified.
    // Avoid a needless rescan of the entire directory.
    if (!scanRecursively && oldFiles == nil)
    {
        [self updateParent:path];
        return;
    }

    [self scanPath:path recursive:NO];
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
