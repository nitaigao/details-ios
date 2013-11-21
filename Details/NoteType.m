#import "NoteType.h"

@implementation NoteType

@synthesize fileInfo, title;

- (id)initWithFileInfo:(DBFileInfo*)theFileInfo andTitle:(NSString*)theTitle {
  self = [super init];
  if (self) {
    self.fileInfo = theFileInfo;
    self.title = theTitle;

  }
  return self;
}

@end