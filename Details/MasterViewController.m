#import "MasterViewController.h"

#import <Dropbox/Dropbox.h>

#import "NotesCollectionCellView.h"
#import "DetailViewController.h"
#import "NoteType.h"

@interface MasterViewController () {
  NSMutableArray *notes;
}
@end

@implementation MasterViewController

@synthesize refreshControl;

- (void)awakeFromNib {
  [super awakeFromNib];

  [[UINavigationBar appearance] setTitleTextAttributes:
    [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor darkGrayColor], NSForegroundColorAttributeName,
      [UIFont fontWithName:@"ArialMT" size:16.0], NSFontAttributeName,nil]];

  [self.editButtonItem setTitleTextAttributes:
    [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor darkGrayColor], NSForegroundColorAttributeName,
      [UIFont fontWithName:@"ArialMT" size:16.0], NSFontAttributeName,nil] forState:UIControlStateNormal];
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  [self.navigationController.navigationBar setTintColor:[UIColor darkGrayColor]];
  
  notes = [[NSMutableArray alloc] init];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(accountLinked)
                                               name:@"AccountLinked"
                                             object:nil];
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(refreshNotes)
                                               name:@"NoteSaved"
                                             object:nil];
  
  self.refreshControl = [[UIRefreshControl alloc] init];
  [refreshControl addTarget:self action:@selector(refreshNotes:) forControlEvents:UIControlEventValueChanged];
  [self.collectionView addSubview:refreshControl];
  self.collectionView.alwaysBounceVertical = YES;
  
  [self refreshNotes];
}

#pragma mark - Collection View

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
  return notes.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
  NotesCollectionCellView *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
  
  NSArray* gestureRecognizers = [NSArray arrayWithArray:cell.gestureRecognizers];
  
  for (UIGestureRecognizer* gestureRecognizer in gestureRecognizers) {
    [cell removeGestureRecognizer:gestureRecognizer];
  }
  
  UILongPressGestureRecognizer *longpressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(deleteNote:)];
  longpressGesture.minimumPressDuration = 2;
  [cell addGestureRecognizer:longpressGesture];
  cell.tag = indexPath.row;
  
  if (notes.count > indexPath.row) {
    NoteType* noteType = [notes objectAtIndex:indexPath.row];
    cell.previewView.text = noteType.title;
  }

  return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([[segue identifier] isEqualToString:@"showDetail"]) {
    NSIndexPath* indexPath = [[self.collectionView indexPathsForSelectedItems] firstObject];
    NoteType* noteType = notes[indexPath.row];
    [[segue destinationViewController] setDetailItem:noteType];
  }
}

- (IBAction)addNote:(id)sender {
  BOOL isAccountLinked = [DBAccountManager sharedManager].linkedAccount.isLinked;
  
  if (!isAccountLinked) {
    [[DBAccountManager sharedManager] linkFromController:self];
    return;
  }

  NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
  NSString* date = [dateFormatter stringFromDate:[[NSDate alloc] init]];
  NSString* filename = [NSString stringWithFormat:@"%@.txt", date];
  
  DBError* error = nil;
  DBPath* path = [[DBPath alloc] initWithString:filename];
  DBFile* file = [[DBFilesystem sharedFilesystem] createFile:path error:&error];
  [file close];
  
  if (error) {
    NSLog(@"%@", error);
  }
  
  DBFileInfo* fileInfo = [[DBFilesystem sharedFilesystem] fileInfoForPath:path error:&error];
  
  if (error) {
    NSLog(@"%@", error);
  }
  
  NoteType* noteType = [[NoteType alloc] initWithFileInfo:fileInfo andTitle:@"New Note"];
  
  [notes insertObject:noteType atIndex:0];
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
  [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
  //[self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
  [self performSegueWithIdentifier:@"showDetail" sender:self];
}

- (void)refreshNotesBackground {  
  DBError* error = nil;
  NSArray* folderContents = [[DBFilesystem sharedFilesystem] listFolder:[DBPath root] error:&error];
  
  if (error) {
    NSLog(@"%@", error);
  }
  
  NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"path.name" ascending:YES];
  NSArray * descriptors = [NSArray arrayWithObject:valueDescriptor];
  NSArray * sortedArray = [[[folderContents sortedArrayUsingDescriptors:descriptors] reverseObjectEnumerator] allObjects];
  
  [notes removeAllObjects];
  
  for (DBFileInfo* fileInfo in sortedArray) {
    
    DBError* error = nil;
    DBFile* file = [[DBFilesystem sharedFilesystem] openFile:fileInfo.path error:&error];
    
    if (error) {
      NSLog(@"%@", error);
    }
    
    NSString* fileContents = [file readString:&error];
    [file close];
    
    if (error) {
      NSLog(@"%@", error);
    }
    

    NoteType* noteType = [[NoteType alloc] initWithFileInfo:fileInfo andTitle:fileContents];
    [notes addObject:noteType];
  }
  
  [self performSelectorOnMainThread:@selector(refreshNotesFinished) withObject:nil waitUntilDone:NO];
}

- (void)deleteNoteBackground:(NoteType*) noteType {
  DBFileInfo* fileInfo = noteType.fileInfo;
  
  DBError* error = nil;
  [[DBFilesystem sharedFilesystem] deletePath:fileInfo.path error:&error];
  
  if (error) {
    NSLog(@"%@", error);
  }
}

- (void)refreshNotesFinished {
  [self.collectionView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];

  if (self.refreshControl.isRefreshing) {
    [self.refreshControl endRefreshing];
  }
}

- (void)refreshNotes {
  [self performSelectorInBackground:@selector(refreshNotesBackground) withObject:nil];
}

- (IBAction)refreshNotes:(id)sender {
  [self.refreshControl beginRefreshing];
  [self refreshNotes];
}

- (IBAction)deleteNote:(UILongPressGestureRecognizer *)gestureRecognizer {
  if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
    UICollectionViewCell *cell = (UICollectionViewCell *)[gestureRecognizer view];
    NSIndexPath* indexPath = [self.collectionView indexPathForCell:cell];
    
    NoteType* noteType = [notes objectAtIndex:indexPath.row];
    [self performSelectorInBackground:@selector(deleteNoteBackground:) withObject:noteType];
    
    [notes removeObjectAtIndex:indexPath.row];
    [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
  }
}

- (void)accountLinked {
  [self.refreshControl beginRefreshing];
  [self refreshNotes];
}

@end
