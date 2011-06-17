#include <Foundation/Foundation.h>

@protocol FileSystemChangesListener
- (void) fileModified:(NSString *)path;
- (void) fileAdded:(NSString *)path;
- (void) fileDeleted:(NSString *)path;
@end

@interface FSTree : NSObject
{
}

- (id) initWithPathsAndListener:(NSArray*)paths listener:(id<FileSystemChangesListener>)listener;
- (void) updatePath:(NSString *)path;

@end
