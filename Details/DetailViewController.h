#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController<UIGestureRecognizerDelegate, UITextViewDelegate>

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UITextView* noteTextView;

@end
