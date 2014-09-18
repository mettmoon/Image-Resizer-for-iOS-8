//
//  ImageBrowserItem.h
//  ResizeImages
//
//  Created by Baris Metin on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface ImageBrowserItem : NSObject

@property (nonatomic,strong) NSImage* image;
@property (nonatomic,strong) NSString* imageUID;
@property (nonatomic,strong) NSString* path;

- (NSString*)imageUID;
- (NSString *)imageRepresentationType;
- (id)imageRepresentation;

@end
