
#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface TimeTableCell : NSObject

@property (weak, nonatomic) IBOutlet WKInterfaceLabel *timeLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *intervalLabel;

@end
