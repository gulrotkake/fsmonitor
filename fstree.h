#include <Foundation/Foundation.h>

@interface FSTree : NSObject
{
}

- (id) initWithPaths:(NSArray*)paths;
- (void) updatePath:(NSString *)path;

@end
