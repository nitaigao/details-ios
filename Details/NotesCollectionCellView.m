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
    CALayer *layer = [self layer];
    [layer setMasksToBounds:NO];
    [layer setRasterizationScale:[[UIScreen mainScreen] scale]];
    [layer setShouldRasterize:YES];
    [layer setShadowColor:[[UIColor blackColor] CGColor]];
    [layer setShadowOffset:CGSizeMake(0.0f,0.5f)];
    [layer setShadowRadius:4.0f];
    [layer setShadowOpacity:0.2f];
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
