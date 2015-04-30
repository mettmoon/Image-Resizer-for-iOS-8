//
//  IRAppDelegate.m
//  Image Resizer for iOS
//
//  Created by Hayden on 2014. 9. 18..
//  Copyright (c) 2014년 OliveStory. All rights reserved.
//

#import "IRAppDelegate.h"

@implementation IRAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
}
- (IBAction)helpAction:(id)sender {
    [[NSWorkspace sharedWorkspace] openFile:@"https://github.com/mettmoon/Image-Resizer-for-iOS-8" withApplication:@"Safari.app"];
}

@end
