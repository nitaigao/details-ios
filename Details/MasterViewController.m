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
  
  if (notes.count > indexPath.row) {
    NoteType* noteType = [notes objectAtIndex:indexPath.row];
    [cell setTitle:noteType.title];
  }

  return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
  NotesCollectionCellView* cell = (NotesCollectionCellView*)[collectionView cellForItemAtIndexPath:indexPath];
  [cell enableHighlight];
}

- (void)collectionView:(UICollectionView *)collectionView didUnhighlightItemAtIndexPath:(NSIndexPath *)indexPath {
  NotesCollectionCellView* cell = (NotesCollectionCellView*)[collectionView cellForItemAtIndexPath:indexPath];
  [cell disableHighlight];
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
  
  NoteType* noteType = [NoteType createNote];
  
  [notes insertObject:noteType atIndex:0];
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
  [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
  [self performSegueWithIdentifier:@"showDetail" sender:self];
}

- (void)refreshNotesFinished:(NSArray*)refreshedNotes {
  [notes removeAllObjects];
  [notes addObjectsFromArray:refreshedNotes];
  [self.collectionView reloadData];

  if (self.refreshControl.isRefreshing) {
    [self.refreshControl endRefreshing];
  }
}

- (void)refreshNotes {
  [NoteType refreshNotes:^(NSArray *refreshedNotes) {
    [self performSelectorOnMainThread:@selector(refreshNotesFinished:) withObject:refreshedNotes waitUntilDone:NO];
  }];
}

- (IBAction)refreshNotes:(id)sender {
  [self.refreshControl beginRefreshing];
  [self refreshNotes];
}

- (void)accountLinked {
  [self.refreshControl beginRefreshing];
  [self refreshNotes];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout  *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
  UIDevice* thisDevice = [UIDevice currentDevice];

  if(thisDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
    return CGSizeMake(240, 200);
  }
  else {
    NSInteger margin = 20;
    if (UIDeviceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
      return CGSizeMake([[UIScreen mainScreen] bounds].size.height - margin, 80.f);
    }
    return CGSizeMake([[UIScreen mainScreen] bounds].size.width - margin, 80.f);
  }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
  [self.collectionView performBatchUpdates:nil completion:nil];
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
  return YES;
}

@end
