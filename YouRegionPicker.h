#import <UIKit/UIKit.h>
#import "BHIManager.h"
@interface YouRegionPicker : UIViewController
@property (nonatomic, copy) void (^onSelect)(NSDictionary *region);
@end
