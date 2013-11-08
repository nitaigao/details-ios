#import <UIKit/UIKit.h>

@class DBAccount;
@class MasterViewController;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) IBOutlet MasterViewController* noteListViewController;

@end
