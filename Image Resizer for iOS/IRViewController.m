//
//  IRViewController.m
//  Image Resizer for iOS
//
//  Created by Hayden on 2014. 9. 18..
//  Copyright (c) 2014년 OliveStory. All rights reserved.
//

#import "IRViewController.h"
#import "ImageBrowserItem.h"
#import "NSImage+Extras.h"

@interface IRViewController ()
@property (weak) IBOutlet IKImageBrowserView *imageBrowser;
@property (nonatomic,strong) NSMutableArray* browserData;
@property (weak) IBOutlet NSTextField *sizeTextField;
@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSSegmentedControl *directionSegmentControl;
@property (weak) IBOutlet NSButton *checkButton;


+ (void)addImageFromPath:(NSString*)path toArray:(NSMutableArray*)array;

@end

@implementation IRViewController
@synthesize imageBrowser = _imageBrowser;
@synthesize browserData = _browserData;
@synthesize progressIndicator = _progressIndicator;
@synthesize checkButton = _checkButton;
@synthesize sizeTextField = _sizeTextField;

- (IBAction)checkAction:(NSButton *)sender {
    BOOL imageSizeEnabled = sender.state==1;
    [self.sizeTextField setEnabled:imageSizeEnabled];
    [self.directionSegmentControl setEnabled:imageSizeEnabled];
}
- (void)viewDidLoad{
    [super viewDidLoad];
    
}
- (IBAction)directionValueChanged:(NSSegmentedControl *)sender {

}

- (IBAction)resizePressed:(NSButton *)sender {
    __block NSMutableArray *__browserData = self.browserData;
    __block IKImageBrowserView *__imageBrowser = self.imageBrowser;
    __block NSProgressIndicator *__progressIndicator = self.progressIndicator;
    CGFloat longestSideLength = [self.sizeTextField floatValue];
    
    [__progressIndicator setHidden:NO];
    [__progressIndicator startAnimation:self];
    [__progressIndicator display];
    [__imageBrowser setAlphaValue:0.4];
    dispatch_queue_t resizeQueue = dispatch_queue_create("Resize Image Queue", NULL);
    dispatch_async(resizeQueue, ^(void) {
        for (ImageBrowserItem* item in __browserData) {
            [self resizeImageUsingImageBrowserItem:item toLongestSide:longestSideLength];
            
        }
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [__browserData removeAllObjects];
            [__imageBrowser reloadData];
            [__progressIndicator stopAnimation:self];
            [__progressIndicator setHidden:YES];
            [__imageBrowser setAlphaValue:1.0];
        });
        
    });
}

- (NSMutableArray*)browserData
{
    if (!_browserData) _browserData = [[NSMutableArray alloc] init];
    return _browserData;
}

- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)aBrowser
{
    return [self.browserData count];
}

- (id)imageBrowser:(IKImageBrowserView *)aBrowser itemAtIndex:(NSUInteger)index
{
    return [self.browserData objectAtIndex:index];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    if ([sender draggingSource] != self) {
        return NSDragOperationEvery;
    }
    return NSDragOperationNone;
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
    return NSDragOperationEvery;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    __block NSMutableArray *__browserData = self.browserData;
    __block IKImageBrowserView *__imageBrowser = self.imageBrowser;
    __block NSProgressIndicator *__progressIndicator = self.progressIndicator;
    NSArray* files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
    
    [__progressIndicator setHidden:NO];
    [__progressIndicator startAnimation:self];
    [__progressIndicator display];
    [__imageBrowser setAlphaValue:0.4];
    dispatch_queue_t addImageQueue = dispatch_queue_create("Add Image Queue", NULL);
    dispatch_async(addImageQueue, ^(void){
        for (id file in files) {
            [IRViewController addImageFromPath:file toArray:__browserData];
        };
        dispatch_sync(dispatch_get_main_queue(), ^(void){
            [__imageBrowser reloadData];
            [__progressIndicator stopAnimation:self];
            [__progressIndicator setHidden:YES];
            [__imageBrowser setAlphaValue:1.0];
        });
    });
    
    return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
    [self.imageBrowser reloadData];
}

+ (void)addImageFromPath:(NSString*)path toArray:(NSMutableArray*)array
{
    NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
    // add files in the directory recursively
    if ([attrs valueForKey:NSFileType] == NSFileTypeDirectory) {
        NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
        for (NSString* content in contents) {
            NSString *contentPath = [path stringByAppendingPathComponent:content];
            [self addImageFromPath:contentPath toArray:array];
        }
        return;
    }
    
    // Allow certain file extensions

    if ([[path pathExtension] caseInsensitiveCompare:@"png"] != NSOrderedSame) {
        NSLog(@"file is not PNG");
        return;
    }
    NSImage* image = [NSImage thumbnailFromPath:path];
    NSString* imageID = [path lastPathComponent];
    ImageBrowserItem* browserItem = [[ImageBrowserItem alloc] init];
    browserItem.image = image;
    browserItem.imageUID = imageID;
    browserItem.path = path;
    [array addObject:browserItem];
}

- (void)resizeImageUsingImageBrowserItem:(ImageBrowserItem *)item toLongestSide:(CGFloat)longestSide
{
    NSBitmapImageRep* imageRep = [NSBitmapImageRep imageRepWithContentsOfFile:item.path];
    // Issues with some PNG files: https://discussions.apple.com/thread/1976694?start=0&tstart=0
    if (!imageRep) return;
    NSSize size = [imageRep size];
    for(NSNumber *number in @[@(3),@(2)]){
        if((int)size.width % number.integerValue != 0 || (int)size.height % number.integerValue != 0){
            NSLog(@"%@ is not multiple of %@",item.path,number.stringValue);
            //            return;
        }
    }
    
    NSString *saveFolderPath = [[item.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"Resized Images"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:saveFolderPath isDirectory:NULL]) {
        [fileManager createDirectoryAtPath:saveFolderPath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:NULL];
    }
    
    
    CGFloat originalScale = 3;
    BOOL fixedSize = self.checkButton.state == 1;
    for(NSNumber *number in @[@(1),@(2),@(3)]){
        NSString *nameExtention = @"";
        if(number.integerValue >1){
            nameExtention = [NSString stringWithFormat:@"@%@x",number.stringValue];
        }
        NSString *saveFileName = [[[[item.path lastPathComponent] stringByDeletingPathExtension] stringByAppendingString:nameExtention] stringByAppendingPathExtension:[item.path pathExtension]];
        CGFloat scaleRatio = number.integerValue / originalScale;
        if(fixedSize){
            if(self.directionSegmentControl.selectedSegment==0){
                scaleRatio /= size.width  / 3 /longestSide;
            }else{
                scaleRatio /= size.height  / 3 /longestSide;
            }
        }
        NSSize targetSize = NSMakeSize(size.width*scaleRatio, size.height*scaleRatio);
        NSImage* resized = [[NSImage alloc] initWithSize:targetSize];
        [resized lockFocus];
        [imageRep drawInRect:NSMakeRect(0, 0, targetSize.width, targetSize.height)];
        [resized unlockFocus];
        NSBitmapImageRep* resizedRep = [NSBitmapImageRep imageRepWithData:[resized TIFFRepresentation]];
        NSData *data = [resizedRep representationUsingType:NSPNGFileType properties:nil];
        [data writeToFile:[saveFolderPath stringByAppendingPathComponent:saveFileName] atomically:YES];
    }
    
    
    
    
}


@end
