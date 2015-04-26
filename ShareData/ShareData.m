
#import "ShareData.h"
#import "Common.h"

@implementation ShareData

#pragma mark - 共有リスト

+ (NSArray*)loadSharedList {
	
	NSURL *shareFileURL = [[NSFileManager defaultManager]
						   containerURLForSecurityApplicationGroupIdentifier:APP_GROUP_NAME];
	shareFileURL = [shareFileURL URLByAppendingPathComponent:@"sharedList.plist"];
	
#if 1
	return [ShareData intevalListToDateList:[NSMutableArray arrayWithContentsOfURL:shareFileURL]];
#else
	return [NSMutableArray arrayWithContentsOfURL:shareFileURL];
#endif
}

+ (void)saveSharedList:(NSArray*)list {
	
	NSURL *shareFileURL = [[NSFileManager defaultManager]
						   containerURLForSecurityApplicationGroupIdentifier:APP_GROUP_NAME];
	shareFileURL = [shareFileURL URLByAppendingPathComponent:@"sharedList.plist"];
	
#if 1
	[[ShareData dateListToIntervalList:list] writeToURL:shareFileURL atomically:YES];
#else
	[list writeToURL:shareFileURL atomically:YES];
#endif
}

// データ領域への保存でNSDateのミリ秒が失われるのでNSTimeInterval形式にして保存/読込みする

+ (NSArray*)dateListToIntervalList:(NSArray*)dateList {
	
	NSMutableArray *intervalList = [[NSMutableArray alloc] initWithCapacity:1];

	for(NSDate *date in dateList) {
		NSTimeInterval interval = [date timeIntervalSince1970];
		[intervalList addObject:[NSNumber numberWithDouble:interval]];
	}
	
	return intervalList;
}

+ (NSArray*)intevalListToDateList:(NSArray*)intervalList {
	
	NSMutableArray *dateList = [[NSMutableArray alloc] initWithCapacity:1];
	
	for(NSNumber *interval in intervalList) {
		NSDate *date = [NSDate dateWithTimeIntervalSince1970:[interval doubleValue]];
		[dateList addObject:date];
	}
	
	return dateList;
}

#pragma mark - 共有UserDefault

+ (id)objectForKey:(NSString*)keyName {
	
	return [[[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_NAME] objectForKey:keyName];
}

+ (void)setObject:(id)object forKey:(NSString*)keyName {
	
	[[[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_NAME] setObject:object forKey:keyName];
	[[[NSUserDefaults alloc] initWithSuiteName:APP_GROUP_NAME] synchronize];
}


@end
