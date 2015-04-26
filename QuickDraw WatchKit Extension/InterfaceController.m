
#import "InterfaceController.h"
#import "Common.h"
#import "ShareData.h"
#import "TimeTableCell.h"

static id	myObj;	// C関数からselfへのアクセスポインタ

@interface InterfaceController() {
	
	NSMutableArray	*shareList;	// iPhoneとAppleWatchで共有するリスト
}

@property (weak, nonatomic) IBOutlet WKInterfaceButton *shootButton;
@property (weak, nonatomic) IBOutlet WKInterfaceTable *timeTable;

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

	// Cの関数でObjective-Cのメソッドを呼び出すための準備
	myObj = self;
	
	// iOS側からの通知を受け取る準備
	[self addObserver];
}

- (void)willActivate {
    [super willActivate];

	// 最初に共有リストをクリア
	shareList = [[NSMutableArray alloc] initWithCapacity:1];
	[ShareData saveSharedList:shareList];

	// 先攻・後攻を決める
	BOOL flag = [[ShareData objectForKey:@"watch_first"] boolValue];
	[self setButtonEnabled:flag];
}

- (void)didDeactivate {
    [super didDeactivate];
}

#pragma mark - ボタンが押されたときの処理

- (IBAction)shootButtonPushed {
	
	// 現在時刻を追加
	[shareList addObject:[NSDate new]];
	
	// 直前の時刻との差分を求める
	NSTimeInterval delta;
	if(shareList.count > 1) {
		NSDate *d1 = [shareList objectAtIndex:shareList.count-1];
		NSDate *d2 = [shareList objectAtIndex:shareList.count-2];
		delta = [d1 timeIntervalSinceDate:d2];
		[self setFastestTime:delta];
	}
	
	// 共有コンテナに保存
	[ShareData saveSharedList:shareList];
	// 表示内容を更新
	[self refreshInformation];
	
	// 相手の番
	[self yourTurn];
}

// ベスト記録を保存する
- (void)setFastestTime:(NSTimeInterval)thisTime {
	
	if(thisTime <= 0.0)
		return;
	
	NSTimeInterval lastBestTime = [self getFastestTime];
	if((lastBestTime <= 0.0)||(thisTime < lastBestTime)) {
		[ShareData setObject:[NSNumber numberWithDouble:thisTime] forKey:@"BestTime"];
		[ShareData setObject:@"Watch" forKey:@"Which"];
	}
}

// ベスト記録を読み込む
- (NSTimeInterval)getFastestTime {
	
	NSNumber *bestTime = [ShareData objectForKey:@"BestTime"];
	return [bestTime doubleValue];
}

#pragma mark - 別プロセスとのヤリトリ

- (void)yourTurn {
	
	// こちらのボタンを使えなくする
	[self setButtonEnabled:NO];
	
	// 相手に通知
	[self sendEventToOwnerApp];
}

- (void)myTurn {
	
	// 表示内容を更新
	shareList = [[NSMutableArray alloc] initWithArray:[ShareData loadSharedList]];
	[self refreshInformation];
	
	// こちらのボタンを使えるようにする
	[self setButtonEnabled:YES];
}

- (void)setButtonEnabled:(BOOL)flag {
	
	if(flag == YES) {
		[_shootButton setEnabled:YES];
		[_shootButton setBackgroundColor:MY_TURN_COLOR];
	}
	else {
		[_shootButton setEnabled:NO];
		[_shootButton setBackgroundColor:YOUR_TURN_COLOR];
	}
}

// iOSアプリにボタン番号を伝達する
- (void)sendEventToOwnerApp {
	
	// 送信する情報
	NSDictionary *requst = @{@"info":@""};
	
	// iOSアプリへ情報を送信し、応答を受信する
	[InterfaceController openParentApplication:requst reply:^(NSDictionary *replyInfo, NSError *error) {
		
		if (error) {
			NSLog(@"%@", error);	// エラー時の処理
		}
	}];
}

// iOS側からの通知（プロセス間通知）を受け取る関数を事前登録しておく
- (void)addObserver {
	
	// iOS側から通知を受けた時のコールバック関数を登録
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
									NULL,
									MyCallBack,			// コールバック関数
									(CFStringRef)GLOBAL_NOTIFY_NAME,
									NULL,
									CFNotificationSuspensionBehaviorDeliverImmediately);
}

// iOS側から通知を受けた時に呼び出される関数
static void MyCallBack(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	
	// Objective-CのmyTurnメソッドをコール
	SEL selector = @selector(myTurn);
	((void (*)(id, SEL))[myObj methodForSelector:selector])(myObj, selector);
}


#pragma mark - Table job

#define MAX_ROW_COUNT	4

// 表示内容を更新
- (void)refreshInformation {
	
	// テーブルにshareList.count行のTimeTableCellインスタンスをぶら下げる
	[_timeTable setNumberOfRows:MIN(MAX_ROW_COUNT, shareList.count) withRowType:@"TimeTableCell"];
	
	// 各行のTimeTableCellインスタンスに表示データを設定する
	for(int i=0; (i < shareList.count)&&(i < MAX_ROW_COUNT); i++) {
		
		// i行目のTimeTableCellインスタンスを取得
		TimeTableCell* row = [_timeTable rowControllerAtIndex:i];
		
		int index = (int)shareList.count-i-1;
		
		// 直前の時刻との差分を求める
		NSTimeInterval delta;
		if(index-1 >= 0) {
			NSDate *d1 = [shareList objectAtIndex:index];
			NSDate *d2 = [shareList objectAtIndex:index-1];
			delta = [d1 timeIntervalSinceDate:d2];
		}
		else {
			delta = 0.0;
		}
		
		// ラベルに表示するデータを設定
		NSDate *eventDate  = [shareList objectAtIndex:index];
		[row.timeLabel		setText:[self getTime:eventDate withFormat:@"mm:ss.SSS"]];
		[row.intervalLabel	setText:[NSString stringWithFormat:@"%2.3f", delta]];
	}
}

- (NSString*)getTime:(NSDate*)targetDate withFormat:(NSString*)format {
	
	NSDateFormatter *outputDateFormatter = [[NSDateFormatter alloc] init];
	[outputDateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"JST"]];
	[outputDateFormatter setDateFormat:format];

	return [outputDateFormatter stringFromDate:targetDate];
}


@end



