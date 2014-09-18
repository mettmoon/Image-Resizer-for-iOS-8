//
//  NSImage+Extras.h
//  ResizeImages
//
//  Created by Baris Metin on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (Extras)

+ (NSImage*)thumbnailFromPath:(NSString*)path;

@end
