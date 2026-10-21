#import <UIKit/UIKit.h>
@interface YouRegionPicker : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate>
@property (nonatomic, copy) void (^onSelect)(NSDictionary *region);
@end
