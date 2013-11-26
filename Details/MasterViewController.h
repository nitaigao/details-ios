#import <UIKit/UIKit.h>

@class DBAccount;
@class NoteType;

@interface MasterViewController : UICollectionViewController

@property (nonatomic, strong) UIRefreshControl* refreshControl;

- (void)refreshNotes;

- (IBAction)refreshNotes:(id)sender;
- (IBAction)addNote:(id)sender;

- (void)deleteSelectedItem;
- (void)refreshSelectedItem:(NoteType*)noteType;

@end
