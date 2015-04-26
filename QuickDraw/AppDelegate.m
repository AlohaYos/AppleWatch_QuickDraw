
#import "AppDelegate.h"
#import "Common.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

	return YES;
}

// WatchKit extensionとの会話
- (void)application:(UIApplication *)application handleWatchKitExtensionRequest:(NSDictionary *)userInfo reply:(void (^)(NSDictionary *))reply{
	
	// 情報が更新されたことをViewControllerへアプリ内通知し、
	// Apple Watchから渡されたuserInfoパラメータ（内容はボタン番号）を渡す
	NSNotification *n =	[NSNotification notificationWithName:APP_NOTIFY_NAME object:self userInfo:userInfo];
	[[NSNotificationCenter defaultCenter] postNotification:n];
	
	// Apple Watchへ応答を返す
	NSDictionary *response;
	response = @{@"response" : @""};
	reply(response);
}


// 情報が更新された時の通知先（アプリ内）を登録する
- (void)registerLifeLogAddNotificationTo:(id)target selector:(SEL)selector {
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:target selector:selector name:APP_NOTIFY_NAME object:nil];
}

@end
