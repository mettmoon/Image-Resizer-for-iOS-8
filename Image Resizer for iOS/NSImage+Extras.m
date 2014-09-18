//
//  NSImage+Extras.m
//  ResizeImages
//
//  Created by Baris Metin on 2/25/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSImage+Extras.h"

@implementation NSImage (Extras)

+ (NSImage*)thumbnailFromPath:(NSString *)path
{
    NSImage *sourceImage = [[NSImage alloc] initWithContentsOfFile:path];
    [sourceImage setSize:NSMakeSize(64, 64)];
    return sourceImage;
}

@end
