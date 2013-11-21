#import "MasterViewController.h"

#import <Dropbox/Dropbox.h>

#import "DetailViewController.h"
#import "NoteType.h"

@interface MasterViewController () {
  NSMutableArray *notes;
}
@end

@implementation MasterViewController

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
  
  UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
  [refreshControl addTarget:self action:@selector(refreshNotes:) forControlEvents:UIControlEventValueChanged];
  [self setRefreshControl:refreshControl];
  
  [self refreshNotes];
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return notes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
  
  if (notes.count > indexPath.row) {
    NoteType* noteType = [notes objectAtIndex:indexPath.row];
    cell.textLabel.text = noteType.title;
  }
  
  return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  if (editingStyle == UITableViewCellEditingStyleDelete) {
    NoteType* noteType = [notes objectAtIndex:indexPath.row];
    DBFileInfo* fileInfo = noteType.fileInfo;
    
    DBError* error = nil;
    [[DBFilesystem sharedFilesystem] deletePath:fileInfo.path error:&error];
    
    if (error) {
      NSLog(@"%@", error);
    }
    
    [notes removeObjectAtIndex:indexPath.row];
    [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
  } else if (editingStyle == UITableViewCellEditingStyleInsert) { }
  
  if (notes.count <= 0) {
    [self performSelector:@selector(finishEditing) withObject:nil afterDelay:0.1];
  }
}

- (void)finishEditing {
  [self setEditing:NO animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([[segue identifier] isEqualToString:@"showDetail"]) {
    NSIndexPath* indexPath = [self.tableView indexPathForSelectedRow];
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
  [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
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

- (void)refreshNotesFinished {
  [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];

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

- (void)accountLinked {
  [self.refreshControl beginRefreshing];
  [self refreshNotes];
}

@end
