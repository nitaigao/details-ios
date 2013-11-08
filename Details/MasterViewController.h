#import <UIKit/UIKit.h>

@class DBAccount;

@interface MasterViewController : UITableViewController

- (void)refreshNotes;

- (IBAction)refreshNotes:(id)sender;
- (IBAction)addNote:(id)sender;

@end
