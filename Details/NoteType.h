#import <Foundation/Foundation.h>

@class DBFileInfo;

@interface NoteType : NSObject

- (id)initWithFileInfo:(DBFileInfo*)fileInfo andTitle:(NSString*)title;
- (void)save:(NSString*)noteText;
- (void)delete;

+ (NoteType*)createNote;
+ (void)refreshNotes:(void (^) (NSArray* notes))refreshCompleteHandler;

@property (nonatomic, strong) DBFileInfo* fileInfo;
@property (nonatomic, strong) NSString* title;

@end