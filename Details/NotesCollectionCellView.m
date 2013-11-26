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
  [self disableHighlight];
}

- (void)enableHighlight {
  CGRect overlayFrame = self.contentView.frame;
  UIView *overlayView = [[UIView alloc] initWithFrame:overlayFrame];
  
  overlayView.alpha = 0.5f;
  overlayView.tag = 1;
  
  overlayView.backgroundColor = [UIColor lightGrayColor];
  
  [self addSubview:overlayView];
}

- (void)disableHighlight {
  [[self viewWithTag:1] removeFromSuperview];
}

- (void)setTitle:(NSString *)title {
  self.previewView.text = title;
}

@end
