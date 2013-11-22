#import <Foundation/Foundation.h>

@class DBFileInfo;

@interface NoteType : NSObject

- (id)initWithFileInfo:(DBFileInfo*)fileInfo andTitle:(NSString*)title;

@property (nonatomic, strong) DBFileInfo* fileInfo;
@property (nonatomic, strong) NSString* title;

@end