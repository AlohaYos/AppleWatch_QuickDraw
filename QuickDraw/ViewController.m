
#import "ViewController.h"
#import "Common.h"
#import "AppDelegate.h"
#import "ShareData.h"

@interface ViewController () {

	AppDelegate*	appDelegate;
	NSMutableArray	*shareList;	// iPhoneとAppleWatchで共有するリスト
}

@property (weak, nonatomic) IBOutlet UIButton *shootButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *bestTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *bestTimeDevice;

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	// 最初に共有リストをクリア
	shareList = [[NSMutableArray alloc] initWithCapacity:1];
	[ShareData saveSharedList:shareList];

	// ベストタイムをクリア
	[ShareData setObject:[NSNumber numberWithDouble:-1.0] forKey:@"BestTime"];

	// 情報が更新された時のアプリ内通知を登録
	appDelegate = [UIApplication sharedApplication].delegate;
	[appDelegate registerLifeLogAddNotificationTo:self selector:@selector(myTurn)];

	// 先攻・後攻を決める
	BOOL flag = [[ShareData objectForKey:@"watch_first"] boolValue];
	[self setButtonEnabled:(!flag)];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

#pragma mark - ボタンが押されたときの処理

- (IBAction)shootButtonPushed:(id)sender {
	
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
	[self refreshInfomation];
	
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
		[ShareData setObject:@"iPhone" forKey:@"Which"];
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
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)GLOBAL_NOTIFY_NAME, NULL, NULL, YES);
}

- (void)myTurn {
	
	// 表示内容を更新
	shareList = [[NSMutableArray alloc] initWithArray:[ShareData loadSharedList]];
	[self refreshInfomation];
	
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

#pragma mark - 表示に関する処理

#define MAX_ROW_COUNT	10

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return MIN(MAX_ROW_COUNT, shareList.count);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
	
	int index = (int)shareList.count-indexPath.row-1;

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
	cell.textLabel.text = [self getTime:eventDate withFormat:@"HH:mm:ss.SSS"];
	cell.detailTextLabel.text = [NSString stringWithFormat:@"%2.3f", delta];
	
	return cell;
}

- (NSString*)getTime:(NSDate*)targetDate withFormat:(NSString*)format {
	
	NSDateFormatter *outputDateFormatter = [[NSDateFormatter alloc] init];
	[outputDateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"JST"]];
	[outputDateFormatter setDateFormat:format];
	
	return [outputDateFormatter stringFromDate:targetDate];
}

// 表示内容を更新
- (void)refreshInfomation {
	
	// TableView
	[_tableView reloadData];
	
	// ベストタイム
	double bestTime = [[ShareData objectForKey:@"BestTime"] doubleValue];
	if(bestTime > 0) {
		_bestTimeDevice.text = [NSString stringWithFormat:@"%@", [ShareData objectForKey:@"Which"]];
		_bestTimeLabel.text = [NSString stringWithFormat:@"%2.3f", bestTime];
	}
}



@end
