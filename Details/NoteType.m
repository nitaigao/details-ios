#import "NoteType.h"

#import <Dropbox/Dropbox.h>

@implementation NoteType

@synthesize fileInfo, title;

- (id)initWithFileInfo:(DBFileInfo*)theFileInfo {
  self = [super init];
  if (self) {
    self.fileInfo = theFileInfo;
    [self setTitleFromBody:@""];
  }
  return self;
}

- (id)initWithFileInfo:(DBFileInfo*)theFileInfo andTitle:(NSString*)theTitle {
  self = [self initWithFileInfo:theFileInfo];
  if (self) {
    [self setTitleFromBody:theTitle];
  }
  return self;
}

- (void)saveBackground:(NSString*)noteText {
  DBError* error = nil;
  
  DBFile* file = [[DBFilesystem sharedFilesystem] openFile:fileInfo.path error:&error];
  
  if (error) {
    NSLog(@"%@", error);
  }
  
  [file writeString:noteText error:&error];
  
  if (error) {
    NSLog(@"%@", error);
  }
  
  [file close];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"NoteSaved" object:nil];
}

- (void)save:(NSString*)noteText {
  [self performSelectorInBackground:@selector(saveBackground:) withObject:noteText];
}

- (void)deleteBackground {
  
  DBError* error = nil;
  [[DBFilesystem sharedFilesystem] deletePath:fileInfo.path error:&error];
  
  if (error) {
    NSLog(@"%@", error);
  }
}

- (void)delete {
  [self performSelectorInBackground:@selector(deleteBackground) withObject:nil];
}

+ (NoteType*)createNote {
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
  
  NoteType* noteType = [[NoteType alloc] initWithFileInfo:fileInfo];
  
  return noteType;
}

+ (void)refreshNotesBackground:(void (^) (NSArray* notes))refreshCompleteHandler {
  DBError* error = nil;
  NSArray* folderContents = [[DBFilesystem sharedFilesystem] listFolder:[DBPath root] error:&error];
  
  if (error) {
    NSLog(@"%@", error);
  }
  
  NSSortDescriptor *valueDescriptor = [[NSSortDescriptor alloc] initWithKey:@"path.name" ascending:YES];
  NSArray * descriptors = [NSArray arrayWithObject:valueDescriptor];
  NSArray * sortedArray = [[[folderContents sortedArrayUsingDescriptors:descriptors] reverseObjectEnumerator] allObjects];
  
  NSMutableArray* notes = [NSMutableArray array];
  
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
  
  refreshCompleteHandler(notes);
}

+ (void)refreshNotes:(void (^) (NSArray* notes))refreshCompleteHandler {
  [self performSelectorInBackground:@selector(refreshNotesBackground:) withObject:refreshCompleteHandler];
}

- (void)setTitleFromBody:(NSString *)body {
  NSString* noteTitle = body.length > 0 ? body : @"Empty Note";
  
  NSString* newTitle = [[noteTitle componentsSeparatedByString:@"\n"] firstObject];
  
  NSInteger maxLength = 55;
  NSInteger titleSubstringIndex = newTitle.length > maxLength ? maxLength - 1 : newTitle.length;
  NSString* titleString = [newTitle substringToIndex:titleSubstringIndex];
  
  self.title = titleString;
}

@end