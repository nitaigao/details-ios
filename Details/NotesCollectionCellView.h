#import <UIKit/UIKit.h>

@interface NotesCollectionCellView : UICollectionViewCell

- (void)setTitle:(NSString*)title;
- (void)enableHighlight;
- (void)disableHighlight;

@property (nonatomic, weak) IBOutlet UITextView* previewView;

@end
