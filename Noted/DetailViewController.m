#import "DetailViewController.h"

#import "../Dropbox.framework/Headers/Dropbox.h"

@implementation DetailViewController

#pragma mark - Managing the detail item

- (void)viewWillDisappear:(BOOL)animated {
  
  DBFileInfo* fileInfo = self.detailItem;
  
  if (self.noteTextView.text.length > 0) {
    DBError* error = nil;
    
    DBFile* file = [[DBFilesystem sharedFilesystem] openFile:fileInfo.path error:&error];
    
    if (error) {
      NSLog(@"%@", error);
    }
    
    [file writeString:self.noteTextView.text error:&error];
    
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

- (void)viewDidAppear:(BOOL)animated {
  [self.noteTextView becomeFirstResponder];
}

@end
