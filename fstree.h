#include <Foundation/Foundation.h>

@protocol FileSystemChangesListener
- (void) fileModified:(NSString *)path;
- (void) fileAdded:(NSString *)path;
- (void) fileDeleted:(NSString *)path;
@end

@interface FSTree : NSObject
{
}

- (id) initWithListener:(id<FileSystemChangesListener>)listener;
- (void) addPath:(NSString*)path;
- (void) updatePath:(NSString *)path;

- (NSArray*) paths;

@end
