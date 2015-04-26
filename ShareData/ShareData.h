
#import <Foundation/Foundation.h>

@interface ShareData : NSObject

+ (NSArray*)loadSharedList;
+ (void)saveSharedList:(NSArray*)list;
+ (id)objectForKey:(NSString*)keyName;
+ (void)setObject:(id)object forKey:(NSString*)keyName;

@end
