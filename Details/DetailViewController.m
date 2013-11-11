#import "DetailViewController.h"

#import <Dropbox/Dropbox.h>

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)viewDidLoad {
  [self.navigationController.navigationBar setTintColor:[UIColor darkGrayColor]];
}

- (void)saveNote {
  DBFileInfo* fileInfo = self.detailItem;
  
  if (self.noteTextView.text.length > 0) {
    DBError* error = nil;
    
    DBFile* file = [[DBFilesystem sharedFilesystem] openFile:fileInfo.path error:&error];
    
    if (error) {
      NSLog(@"%@", error);
    }
    
    [file writeString:self.noteTextView.text error:&error];
    [file close];
    
    if (error) {
      NSLog(@"%@", error);
    }
  }
  else {
    DBError* error = nil;
    [[DBFilesystem sharedFilesystem] deletePath:fileInfo.path error:&error];
    
    if (error) {
      NSLog(@"%@", error);
    }
  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"NoteSaved" object:nil];
}

- (void)enterBackground {
  [self performSelectorInBackground:@selector(saveNote) withObject:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
  [self performSelectorInBackground:@selector(saveNote) withObject:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)setDetailItem:(id)newDetailItem {
  if (_detailItem != newDetailItem) {
    _detailItem = newDetailItem;    
  }
}

- (void)viewWillAppear:(BOOL)animated {
  if (self.detailItem) {
    DBError* error = nil;
    DBFileInfo* fileInfo = self.detailItem;
    
    DBFile* file = [[DBFilesystem sharedFilesystem] openFile:fileInfo.path error:&error];
    
    if (error) {
      NSLog(@"%@", error);
    }
    
    NSString* fileContents = [file readString:&error];
    
    if (error) {
      NSLog(@"%@", error);
    }
    
    self.noteTextView.text = fileContents;
  }
}

- (void)moveTextViewForKeyboard:(NSNotification*)aNotification up:(BOOL)up {
  NSDictionary* userInfo = [aNotification userInfo];
  NSTimeInterval animationDuration;
  UIViewAnimationCurve animationCurve;
  CGRect keyboardEndFrame;

  [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
  [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
  [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];

  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:animationDuration];
  [UIView setAnimationCurve:animationCurve];
  
  CGRect newFrame = self.noteTextView.frame;
  CGRect keyboardFrame = [self.view convertRect:keyboardEndFrame toView:nil];
  float direction = up ? 1 : -1;
  keyboardFrame.size.height -= self.navigationController.tabBarController.tabBar.frame.size.height;
  newFrame.size.height -= keyboardFrame.size.height * direction;
  self.noteTextView.frame = newFrame;
  
  [UIView commitAnimations];
}

- (void)keyboardWillShown:(NSNotification*)aNotification {
  [self moveTextViewForKeyboard:aNotification up:YES];
}

- (void)keyboardWillHide:(NSNotification*)aNotification {
  [self moveTextViewForKeyboard:aNotification up:NO];
}

- (void)viewDidAppear:(BOOL)animated {
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShown:) name:UIKeyboardWillShowNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackground) name:UIApplicationWillResignActiveNotification object:nil];
  
  if (self.noteTextView.text.length <= 0) {
    [self.noteTextView becomeFirstResponder];
  }
}

@end
