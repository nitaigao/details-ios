#import "NotesCollectionCellView.h"

@implementation NotesCollectionCellView

@synthesize previewView;

- (id)initWithCoder:(NSCoder *)aDecoder {
  self = [super initWithCoder:aDecoder];
  if (self) {
    
    // border radius
    [self.layer setCornerRadius:2.0f];
    
    // border
    [self.layer setBorderColor:[UIColor lightGrayColor].CGColor];
    [self.layer setBorderWidth:0.5f];
    
    // drop shadow
//    [self.layer setShadowColor:[UIColor blackColor].CGColor];
//    [self.layer setShadowOpacity:0.8];
//    [self.layer setShadowRadius:1.0];
//    [self.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
  }
  return self;
}

- (void)prepareForReuse {
  [[self viewWithTag:1] removeFromSuperview];
}

@end
