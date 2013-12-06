#import <Foundation/Foundation.h>

@class DBFileInfo;

@interface NoteType : NSObject

- (id)initWithFileInfo:(DBFileInfo*)fileInfo;
- (id)initWithFileInfo:(DBFileInfo*)fileInfo andTitle:(NSString*)title;

- (void)save:(NSString*)noteText;
- (void)delete;

- (void)setTitleFromBody:(NSString *)body;

+ (NoteType*)createNote;
+ (void)refreshNotes:(void (^) (NoteType* note))noteLoadedHandler;

@property (nonatomic, strong) DBFileInfo* fileInfo;
@property (nonatomic, strong) NSString* title;

@end