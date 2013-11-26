#import "DetailViewController.h"

#import <Dropbox/Dropbox.h>
#import "NoteType.h"

#import "MasterViewController.h"

@interface DetailViewController() {
  NSString* lastBody;
}

@end

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)viewDidLoad {
  [self.navigationController.navigationBar setTintColor:[UIColor darkGrayColor]];
}

- (void)finishedEditing {
  NoteType* noteType = (NoteType*)self.detailItem;
  [noteType setTitleFromBody:self.noteTextView.text];
  
  MasterViewController *parent = (MasterViewController *)[self.navigationController.viewControllers firstObject];
  [parent refreshSelectedItem:noteType];
  
  [self.navigationController popToRootViewControllerAnimated:YES];
  
  [noteType save:self.noteTextView.text];
}

- (void)scheduledSaveNote:(NSTimer *)timer {
  if (!lastBody) {
    NoteType* noteType = timer.userInfo;
    [noteType save:self.noteTextView.text];
  }
  
  if (lastBody && NSOrderedSame != [lastBody compare:self.noteTextView.text]) {
    NoteType* noteType = timer.userInfo;
    [noteType save:self.noteTextView.text];
  }
  
  lastBody = self.noteTextView.text;
  
  if (self.navigationController.topViewController != self) {
    [timer invalidate];
  }
}

- (void)viewWillDisappear:(BOOL)animated {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setDetailItem:(id)newDetailItem {
  if (_detailItem != newDetailItem) {
    _detailItem = newDetailItem;
  }
}

- (void)viewWillAppear:(BOOL)animated {
  if (self.detailItem) {
    DBError* error = nil;
    NoteType* noteType = self.detailItem;
    DBFileInfo* fileInfo = noteType.fileInfo;
    
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
  
  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle: @"Details"
                                                                           style: self.navigationController.navigationItem.leftBarButtonItem.style
                                                                          target: self
                                                                          action: @selector(finishedEditing)];
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
  
  if (self.noteTextView.text.length <= 0) {
    [self.noteTextView becomeFirstResponder];
  }
  
  NoteType* noteType = self.detailItem;
  [NSTimer scheduledTimerWithTimeInterval:3 target:self selector:@selector(scheduledSaveNote:) userInfo:noteType repeats:YES];
}

- (IBAction)deleteNote:(id)sender {
  [self.navigationController popToRootViewControllerAnimated:YES];
  MasterViewController *parent = (MasterViewController *)[self.navigationController.viewControllers firstObject];
  [parent deleteSelectedItem];
}

@end
